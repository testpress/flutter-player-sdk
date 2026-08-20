import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/native_sdk_api.g.dart',
  kotlinOut: 'android/src/main/kotlin/com/tpstreams/tpstreams_player_sdk/generated/NativeSDKApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.tpstreams.tpstreams_player_sdk',
  ),
  swiftOut: 'ios/tpstreams_player_sdk/Sources/tpstreams_player_sdk/generated/NativeSDKApi.g.swift',
  swiftOptions: SwiftOptions(),
))

enum PROVIDER {
  tpstreams,
  testpress,
}

@HostApi()
abstract class NativeSDKApi {
  void initialize(PROVIDER provider, String orgCode, String? authToken, bool allowFallbackToL3);
} 