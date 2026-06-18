import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/player_preferences.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/com/tpstreams/tpstreams_player_sdk/generated/PlayerPreferences.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.tpstreams.tpstreams_player_sdk',
    includeErrorClass: false,
  ),
  swiftOut: 'ios/tpstreams_player_sdk/Sources/tpstreams_player_sdk/generated/PlayerPreferences.g.swift',
  swiftOptions: SwiftOptions(
    includeErrorClass: false
  ),
))

class TPStreamsPlayerPreferences {
  bool enableFullscreen;
  bool enablePlaybackSpeed;
  bool enableCaptions;
  bool showResolutionOptions;
  bool enableSeekButtons;
  int? seekBarColor;

  TPStreamsPlayerPreferences({
    this.enableFullscreen = true,
    this.enablePlaybackSpeed = true,
    this.enableCaptions = true,
    this.showResolutionOptions = true,
    this.enableSeekButtons = true,
    this.seekBarColor,
  });
}
