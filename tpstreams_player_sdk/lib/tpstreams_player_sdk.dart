
import 'tpstreams_player_sdk_platform_interface.dart';

class TpstreamsPlayerSdk {
  Future<String?> getPlatformVersion() {
    return TpstreamsPlayerSdkPlatform.instance.getPlatformVersion();
  }
}
