import Foundation
import Flutter
import TPStreamsSDK

class NativePlayerView: NSObject, FlutterPlatformView {
    var player: TPAVPlayer!
    var playerViewController: TPStreamPlayerViewController?

    func view() -> UIView {
        return playerViewController?.view ?? UIView()
    }

    init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, binaryMessenger messenger: FlutterBinaryMessenger) {
        if let args = args as? [String: String], let assetId = args["assetId"] as? String, let accessToken = args["accessToken"] as? String {
            player = TPAVPlayer(assetID: assetId, accessToken: accessToken)
            playerViewController = TPStreamPlayerViewController()
            playerViewController!.player = player
        }
        super.init()
    }
}
