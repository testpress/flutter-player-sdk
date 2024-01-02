library tpstreams_player_sdk;

export 'tpstreams_player.dart';
export 'player_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum PROVIDER {
  tpstreams,
  testpress,
}

class TPStreamsSDK {
  static String? _orgCode;
  static PROVIDER? _provider;

  static void initialize(
      {PROVIDER provider = PROVIDER.tpstreams, required String orgCode}) {
    if (orgCode.isEmpty) {
      throw Exception("Given OrgCode is empty, please pass a valid orgCode");
    }

    _orgCode = orgCode;
    _provider = provider;

    WidgetsFlutterBinding.ensureInitialized();
    const methodChannel = MethodChannel("tpstreams_player_sdk");
    methodChannel.invokeMethod('initializeNativeSDK', {
      "orgCode": _orgCode,
      "provider": _provider.toString().split('.').last
    });
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
