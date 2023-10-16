import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tpstreams_player_sdk_platform_interface.dart';

/// An implementation of [TpstreamsPlayerSdkPlatform] that uses method channels.
class MethodChannelTpstreamsPlayerSdk extends TpstreamsPlayerSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tpstreams_player_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
