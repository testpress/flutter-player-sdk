import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tpstreams_player_sdk/player_controller.dart';

import 'generated_pigeon.g.dart';

class TPStreamPlayer extends StatefulWidget {
  final String assetId;
  final String accessToken;
  final double aspectRatio;
  final Function(TPStreamsPlayerController controller)? onPlayerCreated;

  const TPStreamPlayer({
    Key? key,
    required this.assetId,
    required this.accessToken,
    this.aspectRatio = 16 / 9,
    this.onPlayerCreated,
  }) : super(key: key);

  @override
  State<TPStreamPlayer> createState() => _TPStreamPlayerState();
}

class _TPStreamPlayerState extends State<TPStreamPlayer> {
  EventChannel? _eventChannel;
  TPStreamsPlayerController? _controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
      color: Colors.black,
      child: AspectRatio(
          aspectRatio: widget.aspectRatio, child: getPlayerNativeView()),
    ));
  }

  Widget getPlayerNativeView() {
    var creationParams = {
      "assetId": widget.assetId,
      "accessToken": widget.accessToken
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PlatformViewLink(
          viewType: 'tpstreams_player_sdk/player_view',
          surfaceFactory:
              (BuildContext context, PlatformViewController controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: const <Factory<
                  OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            return PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: 'tpstreams_player_sdk/player_view',
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
            )..addOnPlatformViewCreatedListener(
                _onAndroidPlatformViewCreated(params.onPlatformViewCreated));
          },
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: 'tpstreams_player_sdk/player_view',
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _setupPlayerChannels,
        );
      default:
        return Text(
            '$defaultTargetPlatform is not yet supported by the web_view plugin');
    }
  }

  void Function(int id) _onAndroidPlatformViewCreated(
      Function platformViewCreatedCallback) {
    return ((int id) {
      _setupPlayerChannels(id);
      platformViewCreatedCallback(id);
    });
  }
  void _setupPlayerChannels(int id) {
    print("setupPlayerChannels $id");
    _eventChannel = EventChannel("tpstreams_player_sdk/player_view.events_$id");
    
    _eventChannel!.receiveBroadcastStream().listen((dynamic event) {
      if (event is Map && event['name'] == 'onNativePlayerCreated') {
        var nativePlayerApi = NativePlayerApi(messageChannelSuffix: id.toString());
        _controller = TPStreamsPlayerController(
          nativePlayerApi,
          _eventChannel!
        );
        widget.onPlayerCreated?.call(_controller!);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }
}
