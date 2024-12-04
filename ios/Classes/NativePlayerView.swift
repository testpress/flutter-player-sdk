import Foundation
import Flutter
import TPStreamsSDK
import AVKit

class NativePlayerView: NSObject, FlutterPlatformView {
    var player: TPAVPlayer! {
        didSet {
            guard let player = player else { return }
            player.onError = sendPlayerErrorEvent
        }
    }
    var playerViewController: TPStreamPlayerViewController?
    var methodChannel: FlutterMethodChannel
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
        methodChannel = FlutterMethodChannel(name: "tpstreams_player_sdk/player_view_\(viewId)", binaryMessenger: messenger)
        eventChannel = FlutterEventChannel(name: "tpstreams_player_sdk/player_view.events_\(viewId)", binaryMessenger: messenger)
        super.init()
        methodChannel.setMethodCallHandler(onMethodCall)
        methodChannel.invokeMethod("onNativePlayerCreated", arguments: viewId)
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
    
    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        guard let player = self.player else {
            result(FlutterError(
                code: "PLAYER_ERROR",
                message: "Native Player was not initialized properly",
                details: nil
            ))
            return
        }

        switch call.method {
        case Methods.play:
            executePlayerAction(player.play, result)
        case Methods.pause:
            executePlayerAction(player.pause, result)
        case Methods.dispose:
            executePlayerAction(self.dispose, result)
        case Methods.getCurrentTime:
            executePlayerAction({ return getCurrentTimeInMillis()}, result)
        case Methods.getDuration:
            executePlayerAction({return getDurationInMillis()}, result)
        case Methods.seek:
            executePlayerAction({ seekToPosition(call.arguments as? Int) }, result)
        case Methods.setPlaybackSpeed:
            executePlayerAction({ setPlaybackSpeed(call.arguments as? Double) }, result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func executePlayerAction(_ action: () throws -> Any, _ result: FlutterResult) {
        do {
            let actionResult = try action()
            if type(of: actionResult) != Void.self {
                result(actionResult)
            } else{
                result(nil)
            }        
        } catch {
            result(FlutterError(code: "PLAYER_ERROR", message: "Error: " + error.localizedDescription, details: nil))
        }
    }
    
    func dispose(){
        removeObservers()
        self.player?.replaceCurrentItem(with: nil)
        self.player = nil
    }
    
    private func getCurrentTimeInMillis() -> Int {
        return Int(self.player.currentTime().seconds.rounded(.up) * 1000)
    }

    private func getDurationInMillis() -> Int {
        let duration = self.player.currentItem?.duration.seconds ?? 0.0
        if duration.isFinite && !duration.isNaN {
            return Int(duration.rounded(.up)) * 1000
        } else {
            return 0
        }
    }
    
    private func seekToPosition(_ position: Int?) {
        if let position = position {
            player.seek(to: CMTime(value: CMTimeValue(position), timescale: 1000))
        }
    }

    private func setPlaybackSpeed(_ speed: Double?) {
        if let speed = speed {
            player.rate = Float(speed)
        }
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
