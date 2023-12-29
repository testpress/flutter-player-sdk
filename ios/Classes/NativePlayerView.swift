import Foundation
import Flutter
import TPStreamsSDK

class NativePlayerView: NSObject, FlutterPlatformView {
    var player: TPAVPlayer!
    var playerViewController: TPStreamPlayerViewController?
    var methodChannel: FlutterMethodChannel
    private var eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    private var playbackState: PlaybackState = .unknown {
        didSet{
            sendPlayerEvent(eventName: Events.onPlaybackStateChanged, eventPayload: playbackState.rawValue)
        }
    }

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
        self.player?.replaceCurrentItem(with: nil)
        self.player = nil
    }
    
    private func getCurrentTimeInMillis() -> Int {
        return Int(self.player.currentTime().seconds.rounded(.up) * 1000)
    }

    private func getDurationInMillis() -> Int {
        let duration = self.player.currentItem?.duration.seconds.rounded(.up) ?? 0.0
        return Int(duration) * 1000
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
}

extension NativePlayerView: FlutterStreamHandler{
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}


private enum PlaybackState : String{
    case buffering = "buffering",
         ready = "ready",
         ended = "ended",
         unknown = "unknown"
}
