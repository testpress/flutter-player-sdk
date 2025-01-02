import Flutter
import UIKit
import TPStreamsSDK

public class TpstreamsPlayerSdkPlugin: NSObject, FlutterPlugin, NativeSDKApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(PlayerViewFactory(messenger: registrar.messenger()), withId: "tpstreams_player_sdk/player_view") 
    let instance = TpstreamsPlayerSdkPlugin()
    NativeSDKApi.setUp(registrar.messenger(), instance)
  }

  func initialize(provider: Provider, orgCode: String) throws {
    let sdkProvider: TPStreamsSDK.Provider = provider == .testpress ? .testpress : .tpstreams
    TPStreamsSDK.initialize(for: sdkProvider, withOrgCode: orgCode)
  }
}
