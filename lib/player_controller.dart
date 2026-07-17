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

  /// Enables or disables automatic fullscreen mode when the device is rotated to landscape.
  /// Android: Player will automatically enter fullscreen on landscape rotation and exit on portrait rotation.
  /// iOS: Currently a no-op.
  Future<void> enableAutoFullscreenOnRotate() =>
      _nativeApi.enableAutoFullscreenOnRotate();

  /// Disables automatic fullscreen mode on device rotation.
  /// iOS: Currently a no-op.
  Future<void> disableAutoFullscreenOnRotate() =>
      _nativeApi.disableAutoFullscreenOnRotate();

  /// Sets a watermark overlay on the player.
  ///
  /// Use [WatermarkConfig] to configure the watermark. Key fields:
  /// - `text` — Watermark text content.
  /// - `textColor` — Text color as ARGB integer.
  /// - `textSize` — Text size in SP.
  /// - `position` — A gravity name: `TOP_LEFT`, `TOP_CENTER`,
  ///   `TOP_RIGHT`, `CENTER_LEFT`, `CENTER`, `CENTER_RIGHT`, `BOTTOM_LEFT`,
  ///   `BOTTOM_CENTER`, `BOTTOM_RIGHT`.
  /// - `xFraction` / `yFraction` — Dynamic position (0.0–1.0), used instead of `position`.
  /// - `margins` — Uniform margin in DP.
  /// - `marginsLeft` / `marginsTop` / `marginsRight` / `marginsBottom` — Individual margins.
  /// - `opacity` — 0.0 (invisible) to 1.0 (fully opaque).
  /// - `visibleDuringAds` — Show watermark during ads.
  /// - `visibleWhenPaused` — Show watermark when paused.
  /// - `elevation` — Elevation in DP.
  /// - `pingPongFrom` / `pingPongTo` — Gravity names for ping-pong animation.
  /// - `pingPongDurationMs` — Ping-pong animation duration in milliseconds.
  ///
  /// Pass `null` to remove the watermark.
  /// iOS: Currently a no-op.
  Future<void> setWatermark(WatermarkConfig? config) =>
      _nativeApi.setWatermark(config);

  /// Makes the current watermark visible.
  /// iOS: Currently a no-op.
  Future<void> showWatermark() => _nativeApi.showWatermark();

  /// Hides the current watermark.
  /// iOS: Currently a no-op.
  Future<void> hideWatermark() => _nativeApi.hideWatermark();

  /// Removes the watermark entirely.
  /// iOS: Currently a no-op.
  Future<void> removeWatermark() => _nativeApi.removeWatermark();

  /// Updates the watermark position using dynamic fractional coordinates.
  /// [xFraction] and [yFraction] range from 0.0 to 1.0.
  /// iOS: Currently a no-op.
  Future<void> updateWatermarkPosition(double xFraction, double yFraction) =>
      _nativeApi.updateWatermarkPosition(xFraction, yFraction);

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

typedef TestpressPlayerController = TPStreamsPlayerController;
