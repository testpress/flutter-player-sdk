import Flutter
import UIKit
import TPStreamsSDK

public class TpstreamsPlayerSdkPlugin: NSObject, FlutterPlugin, NativeSDKApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(PlayerViewFactory(messenger: registrar.messenger()), withId: "tpstreams_player_sdk/player_view") 
    let instance = TpstreamsPlayerSdkPlugin()
    NativeSDKApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    
    let downloadManager = NativeDownloadManager()
    GetDownloadsStreamStreamHandler.register(with: registrar.messenger(), streamHandler: downloadManager)
    NativeDownloadManagerApiSetup.setUp(binaryMessenger: registrar.messenger(), api: downloadManager)
  }

  func initialize(provider: PROVIDER, orgCode: String, authToken: String?, allowFallbackToL3: Bool) throws {
    let sdkProvider = provider == .testpress ? Provider.testpress : Provider.tpstreams
    TPStreamsSDK.initialize(for: sdkProvider, withOrgCode: orgCode, usingAuthToken: authToken)
    // Note: allowFallbackToL3 is not supported on iOS SDK
  }
}
