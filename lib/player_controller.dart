import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tpstreams_player_sdk/methods.dart';
import 'package:tpstreams_player_sdk/events.dart';
import 'package:tpstreams_player_sdk/errors.dart';

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

class TPStreamsPlayerController extends ValueNotifier<TPStreamsPlayerValue> {
  final MethodChannel? _channel;
  final EventChannel _eventChannel;
  Timer? _positionTimer;

  TPStreamsPlayerController(this._channel, this._eventChannel)
      : super(TPStreamsPlayerValue()) {
    _eventChannel.receiveBroadcastStream().listen(_onNativeEvent);
  }

  Future<void> play() async {
    await _channel!.invokeMethod(Methods.play);
  }

  Future<void> pause() async {
    await _channel!.invokeMethod(Methods.pause);
  }

  Future<void> seek(Duration target) async {
    await _channel!.invokeMethod(Methods.seek, target.inMilliseconds);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _channel!.invokeMethod(Methods.setPlaybackSpeed, speed);
  }

  Future<Duration> getDuration() async {
    int durationInMilliseconds =
        await (_channel!.invokeMethod(Methods.getDuration));
    return Duration(milliseconds: durationInMilliseconds);
  }

  Future<Duration> getCurrentTime() async {
    int currentTimeInMilliseconds =
        await (_channel!.invokeMethod(Methods.getCurrentTime));
    return Duration(milliseconds: currentTimeInMilliseconds);
  }

  Future<void> dispose() async {
    if (Platform.isIOS) {
      await _channel?.invokeMethod(Methods.dispose);
    }
    stopUpdatePositionTimer();
  }

  void _onNativeEvent(dynamic nativeEventData) {
    final Map<dynamic, dynamic> event = nativeEventData;
    final String eventName = event["name"];
    final dynamic payload = event["payload"];

    switch (eventName) {
      case Events.onIsPlayingChanged:
        _handleIsPlayingChanged(payload);
        break;
      case Events.onPlaybackStateChanged:
        _handlePlaybackStateChanged(payload);
        break;
      case Events.onPlayerError:
        _handlePlayerError(payload);
        break;
      default:
    }
  }

  void _handleIsPlayingChanged(dynamic payload) {
    value = value.copyWith(isPlaying: payload);

    if (value.isPlaying) {
      startUpdatePositionTimer();
    } else {
      stopUpdatePositionTimer();
    }
  }

  void _handlePlaybackStateChanged(dynamic payload) {
    final String? playbackState = payload;
    final bool ended = playbackState == 'ended';
    final bool ready = playbackState == 'ready';

    value = value.copyWith(
      isLoading: value.isLoading && !ready,
      isBuffering: playbackState == 'buffering',
      isEnded: ended,
      position: ended ? value.duration : value.position,
    );
    _updateDurationIfNeeded();
    if (ready) startUpdatePositionTimer();
    if (ended) stopUpdatePositionTimer();
  }

  void _handlePlayerError(dynamic errorMessage) {
    value = value.copyWith(error: TPStreamsError(null, errorMessage));
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
}
