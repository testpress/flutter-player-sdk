import 'package:flutter/services.dart';
import 'package:tpstreams_player_sdk/methods.dart';

class TPStreamsPlayerController {
  final MethodChannel? _channel;

  TPStreamsPlayerController(MethodChannel methodChannel)
      : _channel = methodChannel;

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
    int currentTimeInMilliseconds = await (_channel!.invokeMethod(Methods.getCurrentTime));
    return Duration(milliseconds: currentTimeInMilliseconds);
  }

  Future<void> dispose() async {
    await _channel!.invokeMethod(Methods.dispose);
  }
}