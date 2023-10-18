import Foundation
import Flutter
import UIKit
import AVKit

class PlayerNativeView: NSObject, FlutterPlatformView {
    private var textView  = UITextView()

    func view() -> UIView {
        return textView
    }

    init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, binaryMessenger messenger: FlutterBinaryMessenger) {
        print(args)
        if let args = args as? [String: String], let assetId = args["assetId"] as? String {
            textView.text = assetId
        } else {
            textView.text = "Hello"
        }
        super.init()
    }
}