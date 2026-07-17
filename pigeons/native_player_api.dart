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

class WatermarkConfig {
  final String? text;
  final int? textColor;
  final double? textSize;
  final String? position;
  final double? xFraction;
  final double? yFraction;
  final double? margins;
  final double? marginsLeft;
  final double? marginsTop;
  final double? marginsRight;
  final double? marginsBottom;
  final double? opacity;
  final bool? visibleDuringAds;
  final bool? visibleWhenPaused;
  final double? elevation;
  final String? pingPongFrom;
  final String? pingPongTo;
  final int? pingPongDurationMs;

  WatermarkConfig({
    this.text,
    this.textColor,
    this.textSize,
    this.position,
    this.xFraction,
    this.yFraction,
    this.margins,
    this.marginsLeft,
    this.marginsTop,
    this.marginsRight,
    this.marginsBottom,
    this.opacity,
    this.visibleDuringAds,
    this.visibleWhenPaused,
    this.elevation,
    this.pingPongFrom,
    this.pingPongTo,
    this.pingPongDurationMs,
  });
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
  void setMaxResolution(int resolution);
  void enterFullScreen();
  void exitFullScreen();
  void enableAutoFullscreenOnRotate();
  void disableAutoFullscreenOnRotate();
  void setWatermark(WatermarkConfig? config);
  void showWatermark();
  void hideWatermark();
  void removeWatermark();
  void updateWatermarkPosition(double xFraction, double yFraction);
}