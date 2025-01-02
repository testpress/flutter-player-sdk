import 'package:pigeon/pigeon.dart';


@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated_pigeon.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/com/tpstreams/tpstreams_player_sdk/NativePlayerApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.tpstreams.tpstreams_player_sdk',
  ),
  swiftOut: 'ios/Classes/NativePlayerApi.g.swift',
  swiftOptions: SwiftOptions(
    package: 'com.tpstreams.tpstreams_player_sdk',
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
} 