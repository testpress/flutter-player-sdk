import Foundation
import Flutter
import TPStreamsSDK

class NativePlayerView: NSObject, FlutterPlatformView {
    var player: TPAVPlayer!
    var playerViewController: TPStreamPlayerViewController?
    var methodChannel: FlutterMethodChannel

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
        super.init()
        methodChannel.setMethodCallHandler(onMethodCall)
        methodChannel.invokeMethod("onNativePlayerCreated", arguments: viewId);
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
}
