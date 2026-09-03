import 'package:flutter/foundation.dart';
import '../generated/native_sdk_api.g.dart';

class DeviceCapability {
  DeviceCapability._();
  static final DeviceCapability instance = DeviceCapability._();

  final _nativeSdkApi = NativeSDKApi();
  String? _widevineLevel;
  Future<String?>? _future;

  Future<String?> getWidevineLevel() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return Future.value(null);
    }
    if (_widevineLevel != null) return Future.value(_widevineLevel);
    _future ??= _nativeSdkApi.getWidevineSecurityLevel().then((level) {
      _widevineLevel = level;
      return level;
    });
    return _future!;
  }
}
