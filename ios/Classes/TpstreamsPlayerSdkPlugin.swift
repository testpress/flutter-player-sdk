import Flutter
import UIKit
import TPStreamsSDK

public class TpstreamsPlayerSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(PlayerViewFactory(messenger: registrar.messenger()), withId: "tpstreams_player_sdk/player_view")
    let channel = FlutterMethodChannel(name: "tpstreams_player_sdk", binaryMessenger: registrar.messenger())
    let instance = TpstreamsPlayerSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if call.method == "initializeNativeSDK" {
          if let arguments = call.arguments as? [String: Any],
            let orgCode = arguments["orgCode"] as? String,
            let providerString = arguments["provider"] as? String {
              let provider = (providerString == "testpress") ? Provider.testpress : Provider.tpstreams
              TPStreamsSDK.initialize(for: provider, withOrgCode: orgCode)
          }
      } else {
          result(FlutterMethodNotImplemented)
      }
  }
}
