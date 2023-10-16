import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tpstreams_player_sdk_method_channel.dart';

abstract class TpstreamsPlayerSdkPlatform extends PlatformInterface {
  /// Constructs a TpstreamsPlayerSdkPlatform.
  TpstreamsPlayerSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static TpstreamsPlayerSdkPlatform _instance = MethodChannelTpstreamsPlayerSdk();

  /// The default instance of [TpstreamsPlayerSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelTpstreamsPlayerSdk].
  static TpstreamsPlayerSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TpstreamsPlayerSdkPlatform] when
  /// they register themselves.
  static set instance(TpstreamsPlayerSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
