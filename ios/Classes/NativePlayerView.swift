import Foundation
import Flutter
import TPStreamsSDK
import AVKit

class NativePlayerView: NSObject, FlutterPlatformView, NativePlayerApi {
    var player: TPAVPlayer! {
        didSet {
            guard let player = player else { return }
            player.onError = sendPlayerErrorEvent
        }
    }
    var playerViewController: TPStreamPlayerViewController?
    private var eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    private var playerState: PlayerState = .unknown {
        didSet{
            sendPlayerEvent(eventName: Events.onPlaybackStateChanged, eventPayload: playerState.rawValue)
        }
    }
    private var currentItemChangeObservation: NSKeyValueObservation!

    func view() -> UIView {
        return playerViewController?.view ?? UIView()
    }

    init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, binaryMessenger messenger: FlutterBinaryMessenger) {
        if let args = args as? [String: String], let assetId = args["assetId"] as? String, let accessToken = args["accessToken"] as? String {
            player = TPAVPlayer(assetID: assetId, accessToken: accessToken)
            playerViewController = TPStreamPlayerViewController()
            playerViewController!.player = player
        }
        eventChannel = FlutterEventChannel(name: "tpstreams_player_sdk/player_view.events_\(viewId)", binaryMessenger: messenger)      
        super.init()

        NativePlayerApi.setUp(messenger, self, "\(viewId)")

        eventChannel.setStreamHandler(self)
        self.observePlayerStatusChange()
        self.observeCurrentItemChanges()
    }
 
     private func observeCurrentItemChanges(){
         // We're asynchronously setting the `currentItem` in the TPAVPlayer once the asset is fetched via network.
         // So we adding observers on `currentItem` once it has been set.
         
         currentItemChangeObservation = player.observe(\.currentItem, options: [.new]) { [weak self] (_, _) in
             guard let self = self else { return }
             self.observePlayerBufferingStatusChange()
             self.observeVideoEnd()
             self.sendPlayerEvent(eventName: "onNativePlayerCreated", eventPayload: self.viewId)
         }
     }
     
     private func observePlayerStatusChange(){
         player.addObserver(self, forKeyPath: #keyPath(TPAVPlayer.timeControlStatus), options: .new, context: nil)
     }
         
     private func observePlayerBufferingStatusChange(){
         self.player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: .new, context: nil)
         self.player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: .new, context: nil)
         self.player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
     }
     
     private func observeVideoEnd(){
         NotificationCenter.default.addObserver(self, selector:#selector(self.playerDidFinishPlaying),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
     }
 
     override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
         guard let keyPath = keyPath else { return }
         
         switch keyPath {
         case #keyPath(TPAVPlayer.timeControlStatus):
             if let player = object as? TPAVPlayer {
                 sendPlayerEvent(eventName: Events.onIsPlayingChanged, eventPayload: player.timeControlStatus == .playing)
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
    
    func setPlaybackSpeed(_ speed: Double) throws {
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
        removeObservers()
        player.replaceCurrentItem(with: nil)
        player = nil
    }
    
    func sendPlayerErrorEvent(_ error: Error){
        if let tpStreamPlayerError = error as? TPStreamPlayerError {
            sendPlayerEvent(eventName: Events.onPlayerError, eventPayload: tpStreamPlayerError.message)
        }
    }
    
    func sendPlayerEvent(eventName: String, eventPayload: Any) {
        guard let eventSink = eventSink else {
            return
        }
        let event: [String: Any] = [
            "name": eventName,
            "payload": eventPayload
        ]

        eventSink(event)
    }
    
    deinit {
        removeObservers()
    }
    
    func removeObservers() {
        currentItemChangeObservation?.invalidate()
        player.removeObserver(self, forKeyPath: #keyPath(TPAVPlayer.timeControlStatus))
        player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
        player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
        player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
}

extension NativePlayerView: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}


private enum PlayerState : String{
    case buffering = "buffering",
         ready = "ready",
         ended = "ended",
         unknown = "unknown"
}
