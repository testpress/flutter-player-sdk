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

enum WatermarkAnimationType {
  pingPong,
}

class WatermarkAnimation {
  WatermarkAnimation({
    required this.type,
    this.duration = 10000,
  });

  final WatermarkAnimationType type;

  /// Duration in milliseconds. Minimum 100ms.
  final int duration;
}

class WatermarkConfig {
  WatermarkConfig({
    required this.text,
    this.x = 0,
    this.y = 0,
    this.color = 0xFFFFFFFF,
    this.textSize = 14.0,
    this.opacity = 0.3,
    this.animation,
  });

  final String text;
  final int x;
  final int y;
  final int color;
  final double textSize;
  final double opacity;
  final WatermarkAnimation? animation;
}

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
  /// [newPresenceToken] is empty when the app's onPresenceTokenExpired
  /// callback (or no such callback at all) could not produce a fresh token —
  /// the native side treats that as "back off and try again later", the same
  /// as it does for an empty resolveAccessToken.
  void resolvePresenceToken(String newPresenceToken);
  void setMaxResolution(int resolution);
  void setVideoResolution(int resolution);
  void enterFullScreen();
  void exitFullScreen();
  void enableAutoFullscreenOnRotate();
  void disableAutoFullscreenOnRotate();
  void setWatermarks(List<WatermarkConfig> configs);
  void clearWatermarks();
}