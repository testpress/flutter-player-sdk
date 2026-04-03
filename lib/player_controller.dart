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

  /// Enter fullscreen mode
  Future<void> enterFullScreen() => _nativeApi.enterFullScreen();

  /// Exit fullscreen mode
  Future<void> exitFullScreen() => _nativeApi.exitFullScreen();

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
      });
    }
  }

  void startUpdatePositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(_positionUpdateInterval, (_) {
      getCurrentTime().then((currentTime) {
        value = value.copyWith(position: currentTime);
      });
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
