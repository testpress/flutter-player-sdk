import Foundation
import Flutter
import TPStreamsSDK
import AVKit

class NativePlayerView: NSObject, FlutterPlatformView, NativePlayerApi {
    var viewId: Int64
    var player: TPAVPlayer! {
        didSet {
            guard let player = player else { return }
            player.onError = sendPlayerErrorEvent
        }
    }
    var playerViewController: TPStreamPlayerViewController?
    private var playerState: PlayerState = .unknown {
        didSet {
            playerListener.onPlaybackStateChanged(state:playerState.rawValue, completion: handleFlutterCallResult)
        }
    }
 
    private let initializationListener: NativePlayerInitializationListener
    private let playerListener: NativePlayerListener
    private var currentItemChangeObservation: NSKeyValueObservation!
    private var observedItem: AVPlayerItem?
    private var isInitialized = false

    func view() -> UIView {
        return playerViewController?.view ?? UIView()
    }

    init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, binaryMessenger messenger: FlutterBinaryMessenger) {
        self.viewId = viewId
        initializationListener = NativePlayerInitializationListener(binaryMessenger: messenger, messageChannelSuffix: "\(viewId)")
        playerListener = NativePlayerListener(binaryMessenger: messenger, messageChannelSuffix: "\(viewId)")
        
        super.init()

        if let args = args as? [String: Any], let assetId = args["assetId"] as? String {
            let isOfflinePlayback = args["isOfflinePlayback"] as? Bool ?? false
            let autoPlay = args["autoPlay"] as? Bool ?? true
            
            if isOfflinePlayback {
                player = TPAVPlayer(offlineAssetId: assetId)
            } else {
                let accessToken = args["accessToken"] as? String
                let resolution = args["resolution"] as? Int
                player = TPAVPlayer(assetID: assetId, accessToken: accessToken) { [weak self] error in
                    guard let self = self, error == nil, let resolution = resolution else { return }
                    if let quality = self.player?.availableVideoQualities.first(where: { $0.resolution == "\(resolution)p" }) {
                        self.player?.changeVideoQuality(to: quality)
                    } else {
                        NSLog("TPStreamsPlayerSDK: resolution \(resolution)p not available, using default quality")
                    }
                }
            }
            
            playerViewController = TPStreamPlayerViewController()
            playerViewController!.player = player
            
            if autoPlay {
                player.play()
            }
        }
        
        NativePlayerApiSetup.setUp(binaryMessenger: messenger, api: self, messageChannelSuffix: "\(viewId)")
        
        configurePlayerViewController(args: args)
        
        self.observePlayerStatusChange()
        
        if let player = player, player.currentItem != nil {
            notifyPlayerCreated()
        } else {
            self.observeCurrentItemChanges()
        }
    }
    
    private func configurePlayerViewController(args: Any?) {
        guard let args = args as? [String: Any] else { return }
        
        let showDownloadOption = (args["showDownloadOption"] as? Bool) ?? false
        let startInFullscreen = (args["startInFullscreen"] as? Bool) ?? false
        let metadata = args["metadata"] as? [String: String]
        
        let playerPreferences = args["playerPreferences"] as? [Any]
        
        if showDownloadOption || metadata != nil || startInFullscreen || playerPreferences != nil {
            let configBuilder = TPStreamPlayerConfigurationBuilder()
            
            if showDownloadOption {
                configBuilder.showDownloadOption()
            }

            if startInFullscreen {
                configBuilder.setStartInFullscreen(true)
            }
            
            if let metadata = metadata {
                let metadataAny = metadata as [String: Any]
                configBuilder.setDownloadMetadata(metadataAny)
            }
            
            if let prefsList = playerPreferences,
               let prefs = TPStreamsPlayerPreferences.fromList(prefsList) {
                
                configBuilder.enableFullscreen(prefs.enableFullscreen)
                configBuilder.enablePlaybackSpeed(prefs.enablePlaybackSpeed)
                configBuilder.enableCaptions(prefs.enableCaptions)
                configBuilder.showResolutionOptions(prefs.showResolutionOptions)
                configBuilder.enableSeekButtons(prefs.enableSeekButtons)
                
                if let seekBarColor = prefs.seekBarColor {
                    let color = UIColor(argb: Int(seekBarColor))
                    configBuilder.setprogressBarThumbColor(color)
                    configBuilder.setwatchedProgressTrackColor(color)
                }
            }
            
            playerViewController?.config = configBuilder.build()
        }
        playerViewController?.delegate = self
    }
 
     private func observeCurrentItemChanges(){
         // Register KVO to detect currentItem changes (for async online playback)
         currentItemChangeObservation = player.observe(\.currentItem, options: [.new]) { [weak self] (player, _) in
             guard let self = self else { return }
             self.observePlayerBufferingStatusChange()
             notifyPlayerCreated()
         }
     }
     
     private func observePlayerStatusChange(){
         player.addObserver(self, forKeyPath: #keyPath(TPAVPlayer.timeControlStatus), options: .new, context: nil)
     }
         
     private func observePlayerBufferingStatusChange(){
         guard let item = player.currentItem, item !== observedItem else { return }
         
         if let oldItem = observedItem {
             oldItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
             oldItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
             oldItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
             NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: oldItem)
         }
         
         item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: .new, context: nil)
         item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: .new, context: nil)
         item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
         NotificationCenter.default.addObserver(self, selector:#selector(self.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        
         observedItem = item
     }
 
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case #keyPath(TPAVPlayer.timeControlStatus):
            if let player = object as? TPAVPlayer {
                playerListener.onIsPlayingChanged(
                    isPlaying: player.timeControlStatus == .playing,
                    completion: handleFlutterCallResult
                )
            }
        case #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), #keyPath(AVPlayerItem.isPlaybackBufferEmpty):
            if let playerItem = object as? AVPlayerItem {
                handleBufferStatusChange(of: playerItem, keyPath: keyPath)
            }
        case #keyPath(AVPlayerItem.status):
            if player.currentItem?.status == .readyToPlay {
                playerState = .ready
            }
        default:
            break
        }
    }
 
    @objc private func playerDidFinishPlaying() { playerState = .ended }

     private func handleBufferStatusChange(of playerItem: AVPlayerItem, keyPath: String) {
         switch keyPath {
         case #keyPath(AVPlayerItem.isPlaybackBufferEmpty):
             if playerItem.isPlaybackBufferEmpty {
                 playerState = .buffering
             }
         case #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp):
             if playerItem.isPlaybackLikelyToKeepUp {
                 playerState = .ready
             }
         default:
             break
         }
     }

        
    func play() throws {
        player.play()
    }
    
    func pause() throws {
        player.pause()
    }
    
    func seek(position: Int64) throws {
        player.seek(to: CMTime(value: CMTimeValue(position), timescale: 1000))
    }
    
    func setPlaybackSpeed(speed: Double) throws {
        player.rate = Float(speed)
    }
    
    func getDuration() throws -> Int64 {
        let duration = player.currentItem?.duration.seconds ?? 0.0
        if duration.isFinite && !duration.isNaN {
            return Int64(duration * 1000)
        }
        return 0
    }
    
    func getCurrentTime() throws -> Int64 {
        return Int64(player.currentTime().seconds * 1000)
    }
    
    func dispose() throws {
        guard player != nil else { return }
        player.pause()
        removeObservers()
        player.replaceCurrentItem(with: nil)
        player = nil
    }
    
    func resolveAccessToken(newAccessToken: String) {
        // TODO: Implement onAccessTokenExpired event from the DownloadDelegate
    }

    func setMaxResolution(resolution: Int64) {
        // No-op: iOS does not currently support setMaxResolution
        NSLog("setMaxResolution is currently not supported on iOS and will be ignored.")
    }

    func enterFullScreen() {
        playerViewController?.enterFullScreen()
    }

    func exitFullScreen() {
        playerViewController?.exitFullScreen()
    }

    func enableAutoFullscreenOnRotate() throws {
        // No-op: iOS SDK handles auto fullscreen internally
        NSLog("enableAutoFullscreenOnRotate is currently not supported on iOS and will be ignored.")
    }

    func disableAutoFullscreenOnRotate() throws {
        // No-op: iOS SDK handles auto fullscreen internally
        NSLog("disableAutoFullscreenOnRotate is currently not supported on iOS and will be ignored.")
    }

    func setWatermarks(configs: [WatermarkConfig]) throws {
        NSLog("setWatermarks is currently not supported on iOS and will be ignored.")
    }

    func clearWatermarks() throws {
        NSLog("clearWatermarks is currently not supported on iOS and will be ignored.")
    }

    func sendPlayerErrorEvent(_ error: Error, sentryIssueId: String?) {
        if let tpStreamPlayerError = error as? TPStreamPlayerError {
            playerListener.onPlayerError(error:tpStreamPlayerError.message, completion: handleFlutterCallResult)
        }
    }
    
    deinit {
        removeObservers()
    }
    
    func removeObservers() {
        guard player != nil else { return }
        currentItemChangeObservation?.invalidate()
        player.removeObserver(self, forKeyPath: #keyPath(TPAVPlayer.timeControlStatus))
        
        if let item = observedItem {
            item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
            item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
            item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
            observedItem = nil
        }
    }

    private func handleFlutterCallResult(_ result: Result<Void, PigeonError>) {
        if case .failure(let error) = result {
            NSLog("Failed to call flutter from native: \(error.localizedDescription)")
        }
    }

    private func onFullScreenChanged(isFullScreen: Bool) {
        playerListener.onFullScreenChanged(isFullScreen: isFullScreen, completion: handleFlutterCallResult)
    }

    private func notifyPlayerCreated() {
        if !isInitialized {
            initializationListener.onNativePlayerCreated(platformViewId: viewId, completion: handleFlutterCallResult)
            isInitialized = true
        }
    }
}

private enum PlayerState : String{
    case buffering = "buffering",
         ready = "ready",
         ended = "ended",
         unknown = "unknown"
}


extension NativePlayerView: TPStreamPlayerViewControllerDelegate {
    func didEnterFullScreenMode() {
        onFullScreenChanged(isFullScreen: true)
    }
    
    func didExitFullScreenMode() {
        onFullScreenChanged(isFullScreen: false)
    }

    func willEnterFullScreenMode() {
        playerListener.beforeFullScreenEnter(completion: handleFlutterCallResult)
    }

    func willExitFullScreenMode() {
        playerListener.beforeFullScreenExit(completion: handleFlutterCallResult)
    }

    func didTapReplay() {
        playerListener.notifyReplay(completion: handleFlutterCallResult)
    }
}