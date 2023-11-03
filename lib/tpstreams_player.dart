import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TPStreamPlayer extends StatefulWidget {
  final String assetId;
  final String accessToken;
  final double aspectRatio;

  const TPStreamPlayer({
    Key? key,
    required this.assetId,
    required this.accessToken,
    this.aspectRatio = 16 / 9,
  }) : super(key: key);

  @override
  State<TPStreamPlayer> createState() => _TPStreamPlayerState();
}

class _TPStreamPlayerState extends State<TPStreamPlayer> {
  MethodChannel? methodChannel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          color: Colors.black,
          child: AspectRatio(
            aspectRatio: widget.aspectRatio, 
            child: getPlayerNativeView()
          ),
    ));
  }

  Widget getPlayerNativeView() {
    var creationParams = {"assetId": widget.assetId, "accessToken": widget.accessToken};

    switch (defaultTargetPlatform) {
      
      case TargetPlatform.android:
        return PlatformViewLink(
          viewType: 'tpstreams_player_sdk/player_view',
          surfaceFactory: (BuildContext context, PlatformViewController controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
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
            )..addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
          },
        );
      case TargetPlatform.iOS:
        return UiKitView(
            viewType: 'tpstreams_player_sdk/player_view',
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: onIOSPlatformViewCreated,
          );
      default:
        return Text(
            '$defaultTargetPlatform is not yet supported by the web_view plugin');
    }
  }

  onIOSPlatformViewCreated(int id) {
    methodChannel = MethodChannel('tpstreams_player_sdk/player_view_$id');
  }

  @override
  void dispose() {
    super.dispose();
    if (Platform.isIOS) {
      methodChannel?.invokeMethod("dispose");
    }
  }
}
