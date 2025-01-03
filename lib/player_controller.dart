import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tpstreams_player_sdk/errors.dart';

import 'native_player_api.g.dart';
import 'native_player_listeners.g.dart';

/// Represents the state of a streams player.
class TPStreamsPlayerValue {
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

  final TPStreamsError? error;

  /// Creates an instance of [TPStreamsPlayerValue].
  ///
  /// Use this class to represent the state of a streams player, including playback
  /// information, buffering status, and available playback speed options.
  TPStreamsPlayerValue(
      {this.duration = Duration.zero,
      this.position = Duration.zero,
      this.isLoading = false,
      this.isPlaying = false,
      this.isBuffering = false,
      this.isEnded = false,
      this.error});

  TPStreamsPlayerValue copyWith(
      {Duration? duration,
      Duration? position,
      bool? isLoading,
      bool? isPlaying,
      bool? isBuffering,
      bool? isEnded,
      TPStreamsError? error}) {
    return TPStreamsPlayerValue(
        duration: duration ?? this.duration,
        position: position ?? this.position,
        isLoading: isLoading ?? this.isLoading,
        isPlaying: isPlaying ?? this.isPlaying,
        isBuffering: isBuffering ?? this.isBuffering,
        isEnded: isEnded ?? this.isEnded,
        error: error ?? this.error);
  }
}

class TPStreamsPlayerController extends ValueNotifier<TPStreamsPlayerValue> implements NativePlayerListener {
  final int id;
  late NativePlayerApi _nativeApi;
  Timer? _positionTimer;

  TPStreamsPlayerController(this.id) : super(TPStreamsPlayerValue()) {
    _nativeApi = NativePlayerApi(messageChannelSuffix: id.toString());
    NativePlayerListener.setUp(this, messageChannelSuffix: id.toString());
  }

  Future<void> play() async {
    await _nativeApi.play();
  }

  Future<void> pause() async {
    await _nativeApi.pause();
  }

  Future<void> seek(Duration target) async {
    await _nativeApi.seek(target.inMilliseconds);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _nativeApi.setPlaybackSpeed(speed);
  }

  Future<Duration> getDuration() async {
    final durationInMilliseconds = await _nativeApi.getDuration();
    return Duration(milliseconds: durationInMilliseconds);
  }

  Future<Duration> getCurrentTime() async {
    final currentTimeInMilliseconds = await _nativeApi.getCurrentTime();
    return Duration(milliseconds: currentTimeInMilliseconds);
  }

  @override
  void onPlaybackStateChanged(String state) {
    final bool ended = state == 'ended';
    final bool ready = state == 'ready';

    value = value.copyWith(
      isLoading: value.isLoading && !ready,
      isBuffering: state == 'buffering',
      isEnded: ended,
      position: ended ? value.duration : value.position,
    );
    _updateDurationIfNeeded();
    if (ended) stopUpdatePositionTimer();
  }

  @override
  void onIsPlayingChanged(bool isPlaying) {
    value = value.copyWith(isPlaying: isPlaying);
    if (isPlaying) {
      startUpdatePositionTimer();
    } else {
      stopUpdatePositionTimer();
    }
  }

  @override
  void onPlayerError(String error) {
    value = value.copyWith(error: TPStreamsError(null, error));
  }

  void _updateDurationIfNeeded() {
    if (!value.isLoading && value.duration == Duration.zero) {
      getDuration().then((duration) {
        if (duration.inSeconds != 0) value = value.copyWith(duration: duration);
      });
    }
  }

  void startUpdatePositionTimer() {
    _positionTimer?.cancel();

    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      getCurrentTime().then(
          (currentTime) => {value = value.copyWith(position: currentTime)});
    });
  }

  void stopUpdatePositionTimer() {
    _positionTimer?.cancel();
  }

  @override
  void dispose() {
    _nativeApi.dispose();
    stopUpdatePositionTimer();
    super.dispose();
  }
}
