import 'package:flutter_test/flutter_test.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk_platform_interface.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTpstreamsPlayerSdkPlatform
    with MockPlatformInterfaceMixin
    implements TpstreamsPlayerSdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final TpstreamsPlayerSdkPlatform initialPlatform = TpstreamsPlayerSdkPlatform.instance;

  test('$MethodChannelTpstreamsPlayerSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTpstreamsPlayerSdk>());
  });

  test('getPlatformVersion', () async {
    TpstreamsPlayerSdk tpstreamsPlayerSdkPlugin = TpstreamsPlayerSdk();
    MockTpstreamsPlayerSdkPlatform fakePlatform = MockTpstreamsPlayerSdkPlatform();
    TpstreamsPlayerSdkPlatform.instance = fakePlatform;

    expect(await tpstreamsPlayerSdkPlugin.getPlatformVersion(), '42');
  });
}
