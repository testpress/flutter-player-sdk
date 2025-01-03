library tpstreams_player_sdk;

export 'tpstreams_player.dart';
export 'player_controller.dart';
import 'package:flutter/widgets.dart';
import 'generated/native_sdk_api.g.dart';
export 'generated/native_sdk_api.g.dart' show PROVIDER;

class TPStreamsSDK {
  static String? _orgCode;
  static PROVIDER? _provider;
  static final _nativeSdkApi = NativeSDKApi();

  static void initialize({
    PROVIDER provider = PROVIDER.tpstreams,
    required String orgCode,
  }) {
    if (orgCode.isEmpty) {
      throw Exception("Given OrgCode is empty, please pass a valid orgCode");
    }

    _orgCode = orgCode;
    _provider = provider;

    WidgetsFlutterBinding.ensureInitialized();
    _nativeSdkApi.initialize(provider, orgCode);
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
