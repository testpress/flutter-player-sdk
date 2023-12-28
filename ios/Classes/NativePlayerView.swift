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
        methodChannel.invokeMethod("onNativePlayerCreated", id);
    }
    
    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch(call.method){
        case "dispose":
            self.dispose()
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func dispose(){
        self.player?.replaceCurrentItem(with: nil)
        self.player = nil
    }
}
