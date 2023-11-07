import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk.dart';


void main() {
  group('TPStreamsSDK', () {
    MethodChannel channel = const MethodChannel("tpstreams_player_sdk");
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });
    });

    test('initialize with empty orgCode', () {

      expect(() => TPStreamsSDK.initialize(orgCode: ''), throwsException);
      expect(TPStreamsSDK.isInitialized, isFalse);
    });

    test('get orgCode before initialization', () {
      expect(() => TPStreamsSDK.orgCode, throwsException);
    });

    test('check isInitialized before initialization', () {
      expect(TPStreamsSDK.isInitialized, isFalse);
    });

    test('get provider before initialization', () {
      expect(TPStreamsSDK.provider, isNull);
    });

    test('initialize with valid orgCode and default provider', () {
      TPStreamsSDK.initialize(orgCode: 'abc123');

      expect(TPStreamsSDK.isInitialized, isTrue);
      expect(TPStreamsSDK.orgCode, 'abc123');
      expect(TPStreamsSDK.provider, PROVIDER.tpstreams);
    });

    test('initialize with valid orgCode and custom provider', () {
      TPStreamsSDK.initialize(orgCode: 'abc123', provider: PROVIDER.testpress);

      expect(TPStreamsSDK.isInitialized, isTrue);
      expect(TPStreamsSDK.orgCode, 'abc123');
      expect(TPStreamsSDK.provider, PROVIDER.testpress);
    });

    test('initialize and re-initialize with valid orgCode', () {
      TPStreamsSDK.initialize(orgCode: 'abc123');
      expect(TPStreamsSDK.isInitialized, isTrue);
      expect(TPStreamsSDK.orgCode, 'abc123');

      // Re-initialization should not change the orgCode
      TPStreamsSDK.initialize(orgCode: 'newOrgCode');
      expect(TPStreamsSDK.isInitialized, isTrue);
      expect(TPStreamsSDK.orgCode, 'newOrgCode');
    });
  });
}
