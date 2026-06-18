import 'package:pigeon/pigeon.dart';


@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/native_player_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/com/tpstreams/tpstreams_player_sdk/generated/NativePlayerApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.tpstreams.tpstreams_player_sdk',
    includeErrorClass: false,
  ),
  swiftOut: 'ios/tpstreams_player_sdk/Sources/tpstreams_player_sdk/generated/NativePlayerApi.g.swift',
  swiftOptions: SwiftOptions(
    includeErrorClass: false
  ),
))

@HostApi()
abstract class NativePlayerApi {
  void play();
  void pause();
  void seek(int position);
  void setPlaybackSpeed(double speed);
  int getDuration();
  int getCurrentTime();
  void dispose();
  void resolveAccessToken(String newAccessToken);
  void setMaxResolution(int resolution);
  void enterFullScreen();
  void exitFullScreen();
  void enableAutoFullscreenOnRotate();
  void disableAutoFullscreenOnRotate();
}