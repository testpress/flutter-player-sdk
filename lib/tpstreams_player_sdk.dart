library tpstreams_player_sdk;

export 'tpstreams_player.dart';
export 'player_controller.dart';
export 'generated/player_preferences.g.dart';
import 'package:flutter/widgets.dart';
import 'generated/native_sdk_api.g.dart';
export 'generated/native_sdk_api.g.dart' show PROVIDER;
export 'download_manager.dart';
export 'generated/native_download_manager_api.g.dart' show DownloadAsset, DownloadState;
export 'watermark_config.dart';

import 'src/device_capability.dart';

class TPStreamsSDK {
  static String? _orgCode;
  static PROVIDER? _provider;
  static final _nativeSdkApi = NativeSDKApi();

  static void initialize({
    PROVIDER provider = PROVIDER.tpstreams,
    required String orgCode,
    String? authToken,
    bool allowFallbackToL3 = false,
  }) {
    if (orgCode.isEmpty) {
      throw Exception("Given OrgCode is empty, please pass a valid orgCode");
    }

    _orgCode = orgCode;
    _provider = provider;

    WidgetsFlutterBinding.ensureInitialized();
    DeviceCapability.instance.getWidevineLevel();
    _nativeSdkApi.initialize(provider, orgCode, authToken, allowFallbackToL3);
  }

  static String get orgCode {
    if (_orgCode == null) {
      throw Exception("OrgCode has not been initialized");
    }

    return _orgCode!;
  }

  static bool get isInitialized => _orgCode != null;

  static PROVIDER? get provider => _provider;
}

class TestpressSDK {
  static void initialize({
    required String subdomain,
    String? authToken,
    bool allowFallbackToL3 = false,
  }) {
    TPStreamsSDK.initialize(
      provider: PROVIDER.testpress,
      orgCode: subdomain,
      authToken: authToken,
      allowFallbackToL3: allowFallbackToL3,
    );
  }
}
