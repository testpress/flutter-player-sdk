import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelTpstreamsPlayerSdk platform = MethodChannelTpstreamsPlayerSdk();
  const MethodChannel channel = MethodChannel('tpstreams_player_sdk');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
