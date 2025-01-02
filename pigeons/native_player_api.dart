import 'package:pigeon/pigeon.dart';


@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/native_player_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/com/tpstreams/tpstreams_player_sdk/NativePlayerApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.tpstreams.tpstreams_player_sdk',
    includeErrorClass: false,
  ),
  swiftOut: 'ios/Classes/NativePlayerApi.g.swift',
  swiftOptions: SwiftOptions(),
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
} 