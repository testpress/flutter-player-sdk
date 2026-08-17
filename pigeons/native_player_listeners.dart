import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/native_player_listeners.g.dart',
  kotlinOut: 'android/src/main/kotlin/com/tpstreams/tpstreams_player_sdk/generated/NativePlayerListeners.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.tpstreams.tpstreams_player_sdk',
    includeErrorClass: false,
  ),
  swiftOut: 'ios/tpstreams_player_sdk/Sources/tpstreams_player_sdk/generated/NativePlayerListeners.g.swift',
  swiftOptions: SwiftOptions(
    includeErrorClass: false,
  ),
))

@FlutterApi()
abstract class NativePlayerInitializationListener {
  void onNativePlayerCreated(int platformViewId);
}

@FlutterApi()
abstract class NativePlayerListener {
  void onPlaybackStateChanged(String state);
  void onIsPlayingChanged(bool isPlaying);
  void onPlayerError(String error);
  void onFullScreenChanged(bool isFullScreen);
  void beforeFullScreenEnter();
  void beforeFullScreenExit();
  void handleAccessTokenExpiration(String videoId);
  // A 401 from the presence heartbeat loop — an expired token and a device-
  // binding mismatch look identical from here, and both are resolved the
  // same way: fetch a fresh playback config and resolve it via
  // NativePlayerApi.resolvePresenceToken.
  void handlePresenceTokenExpiration(String videoId);
  void notifyReplay();
}