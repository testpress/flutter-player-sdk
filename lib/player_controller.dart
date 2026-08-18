import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tpstreams_player_sdk/errors.dart';

import 'generated/native_player_api.g.dart';
import 'generated/native_player_listeners.g.dart';

/// Represents the state of a streams player.
class TPStreamsPlayerValue {
  static const Object _noErrorUpdate = Object();

  /// Indicates whether a video is currently being loaded into the player.
  final bool isLoading;

  /// The total duration of the video. Defaults to [Duration.zero] if the video is not loaded.
  final Duration duration;

  /// The current playback position in the video.
  final Duration position;

  /// Indicates whether the video is currently playing (true) or paused (false).
  final bool isPlaying;

  /// Indicates whether the video is currently buffering.
  final bool isBuffering;

  /// Indicates whether the currently loaded video has played to the end.
  final bool isEnded;

  /// Indicates whether the video is currently in fullscreen mode.
  final bool isFullScreen;

  /// Any error that occurred during playback
  final TPStreamsError? error;

  const TPStreamsPlayerValue({
    this.isLoading = false,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isEnded = false,
    this.isFullScreen = false,
    this.error,
  });

  TPStreamsPlayerValue copyWith({
    bool? isLoading,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    bool? isBuffering,
    bool? isEnded,
    bool? isFullScreen,
    Object? error = _noErrorUpdate,
  }) {
    return TPStreamsPlayerValue(
      isLoading: isLoading ?? this.isLoading,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isEnded: isEnded ?? this.isEnded,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      error: identical(error, _noErrorUpdate) ? this.error : error as TPStreamsError?,
    );
  }
}

/// Controller for managing video playback in TPStreams player
class TPStreamsPlayerController extends ValueNotifier<TPStreamsPlayerValue> implements NativePlayerListener {
  final int platformViewId;
  late final NativePlayerApi _nativeApi;
  Timer? _positionTimer;

  static const _positionUpdateInterval = Duration(milliseconds: 500);

  VoidCallback? onBeforeFullScreenEnter;

  VoidCallback? onBeforeFullScreenExit;

  VoidCallback? onReplay;

  Future<String> Function(String videoId)? onAccessTokenExpired;

  TPStreamsPlayerController(this.platformViewId) : super(const TPStreamsPlayerValue(isLoading: true)) {
    _nativeApi = NativePlayerApi(messageChannelSuffix: platformViewId.toString());
    NativePlayerListener.setUp(this, messageChannelSuffix: platformViewId.toString());
  }

  /// Start playing the video
  Future<void> play() => _nativeApi.play();

  /// Pause the video
  Future<void> pause() => _nativeApi.pause();

  /// Seek to a specific position in the video
  Future<void> seek(Duration target) => _nativeApi.seek(target.inMilliseconds);

  /// Set the playback speed of the video
  Future<void> setPlaybackSpeed(double speed) => _nativeApi.setPlaybackSpeed(speed);

/// Sets the maximum resolution for video playback.
/// The [resolution] parameter defines the maximum video height in pixels (for example, 720 for 720p).
/// Android: Limits playback to video tracks whose resolution is less than or equal to the specified value. Higher-resolution tracks will not be selected.
/// iOS: Currently a no-op (the setting is ignored).
  Future<void> setMaxResolution(int resolution) => _nativeApi.setMaxResolution(resolution);

  /// Sets the video resolution preference.
  /// The [resolution] parameter defines the desired video height in pixels (for example, 720 for 720p).
  /// Android: Sets the preferred maximum video height. The player will adaptively select tracks up to this height.
  /// iOS: Selects the matching quality from available options.
  Future<void> setVideoResolution(int resolution) => _nativeApi.setVideoResolution(resolution);

  /// Enter fullscreen mode
  Future<void> enterFullScreen() => _nativeApi.enterFullScreen();

  /// Exit fullscreen mode
  Future<void> exitFullScreen() => _nativeApi.exitFullScreen();

  /// Enables or disables automatic fullscreen mode when the device is rotated to landscape.
  /// Android: Player will automatically enter fullscreen on landscape rotation and exit on portrait rotation.
  /// iOS: Currently a no-op.
  Future<void> enableAutoFullscreenOnRotate() =>
      _nativeApi.enableAutoFullscreenOnRotate();

  /// Disables automatic fullscreen mode on device rotation.
  /// iOS: Currently a no-op.
  Future<void> disableAutoFullscreenOnRotate() =>
      _nativeApi.disableAutoFullscreenOnRotate();

  /// Applies text watermark overlays on the video player.
  ///
  /// Pass an empty list to clear all watermarks. Each [WatermarkConfig]
  /// creates an independent watermark overlay.
  ///
  /// iOS: Currently a no-op.
  ///
  /// Supported fields:
  /// - [text]: Watermark text (required).
  /// - [x]: Horizontal position as 0–100 percent (default: 0).
  /// - [y]: Vertical position as 0–100 percent (default: 0).
  /// - [color]: Text color as ARGB int (default: white).
  /// - [textSize]: Text size in SP (default: 14).
  /// - [opacity]: 0.0 (invisible) to 1.0 (fully opaque) (default: 0.3).
  /// - [animation]: Optional animation (e.g., [WatermarkAnimation] with
  ///   [WatermarkAnimationType.pingPong] for a sweep effect).
  Future<void> setWatermarks(List<WatermarkConfig> configs) =>
      _nativeApi.setWatermarks(configs);

  /// Removes all watermarks and frees resources.
  Future<void> clearWatermarks() => _nativeApi.clearWatermarks();

  /// Get the total duration of the video
  Future<Duration> getDuration() async {
    final durationInMilliseconds = await _nativeApi.getDuration();
    return Duration(milliseconds: durationInMilliseconds);
  }

  /// Get the current playback position
  Future<Duration> getCurrentTime() async {
    final currentTimeInMilliseconds = await _nativeApi.getCurrentTime();
    return Duration(milliseconds: currentTimeInMilliseconds);
  }

  @override
  void onPlaybackStateChanged(String state) {
    final bool isEnded = state == 'ended';
    final bool isReady = state == 'ready';
    final bool isBuffering = state == 'buffering';
    final bool shouldKeepLoading =
        !isReady && !isEnded && value.error == null && (isBuffering || value.duration == Duration.zero || value.isLoading);

    value = value.copyWith(
      isLoading: shouldKeepLoading,
      isBuffering: isBuffering,
      isEnded: isEnded,
      position: isEnded ? value.duration : value.position,
      error: isReady ? null : value.error,
    );
    
    _updateDurationIfNeeded();
    if (isEnded) stopUpdatePositionTimer();
  }

  @override
  void onIsPlayingChanged(bool isPlaying) {
    value = value.copyWith(
      isPlaying: isPlaying,
      error: isPlaying ? null : value.error,
    );
    isPlaying ? startUpdatePositionTimer() : stopUpdatePositionTimer();
  }

  @override
  void onPlayerError(String error) {
    value = value.copyWith(
      isLoading: false,
      error: TPStreamsError(null, error),
    );
  }

  @override
  void onFullScreenChanged(bool isFullScreen) {
    value = value.copyWith(isFullScreen: isFullScreen);
  }

  @override
  void beforeFullScreenEnter() {
    onBeforeFullScreenEnter?.call();
  }

  @override
  void beforeFullScreenExit() {
    onBeforeFullScreenExit?.call();
  }

  @override
  void notifyReplay() {
    onReplay?.call();
  }

  @override
  void handleAccessTokenExpiration(String videoId) async {
    if (onAccessTokenExpired != null) {
      final newToken = await onAccessTokenExpired!(videoId);
      _nativeApi.resolveAccessToken(newToken);
    }
  }

  void _updateDurationIfNeeded() {
    if (!value.isLoading && value.duration == Duration.zero) {
      getDuration().then((duration) {
        if (duration.inSeconds > 0) {
          value = value.copyWith(duration: duration);
        }
      }).catchError((_) {});
    }
  }

  void startUpdatePositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(_positionUpdateInterval, (_) {
      getCurrentTime().then((currentTime) {
        value = value.copyWith(position: currentTime);
      }).catchError((_) {});
    });
  }

  void stopUpdatePositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  @override
  void dispose() {
    _nativeApi.dispose();
    stopUpdatePositionTimer();
    super.dispose();
  }
}

typedef TestpressPlayerController = TPStreamsPlayerController;
