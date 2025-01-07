import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tpstreams_player_sdk/player_controller.dart';

import 'generated/native_player_api.g.dart';
import 'generated/native_player_listeners.g.dart';


class TPStreamPlayer extends StatefulWidget {
  final String assetId;
  final String? accessToken;
  final double aspectRatio;
  final Function(TPStreamsPlayerController controller)? onPlayerCreated;
  final bool? showDownloadOption;
  final int? offlineLicenseExpireDays;
  final bool _isOfflinePlayback;

  const TPStreamPlayer({
    super.key,  
    required this.assetId,
    required this.accessToken,
    this.aspectRatio = 16 / 9,
    this.onPlayerCreated,
    this.showDownloadOption = false,
    this.offlineLicenseExpireDays = 15,
  }) : _isOfflinePlayback = false;

  const TPStreamPlayer.offline({
    super.key,
    required String assetId,
    this.aspectRatio = 16 / 9,
    Function(TPStreamsPlayerController controller)? onPlayerCreated,
  }) : assetId = assetId,
       accessToken = null,
       showDownloadOption = false,
       offlineLicenseExpireDays = 15,
       onPlayerCreated = onPlayerCreated,
       _isOfflinePlayback = true;

  @override
  State<TPStreamPlayer> createState() => _TPStreamPlayerState();
}

class _TPStreamPlayerState extends State<TPStreamPlayer> implements NativePlayerInitializationListener {
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
      "accessToken": widget.accessToken,
      "isOfflinePlayback": widget._isOfflinePlayback,
      "showDownloadOption": widget.showDownloadOption,
      "offlineLicenseExpireDays": widget.offlineLicenseExpireDays,
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
          onPlatformViewCreated: setUpNativePlayerInitializationListener,
        );
      default:
        return Text(
            '$defaultTargetPlatform is not yet supported by the web_view plugin');
    }
  }

  void Function(int id) _onAndroidPlatformViewCreated(
      Function platformViewCreatedCallback) {
    return ((int id) {
      setUpNativePlayerInitializationListener(id);
      platformViewCreatedCallback(id);
    });
  }

  void setUpNativePlayerInitializationListener(int id) {
    NativePlayerInitializationListener.setUp(this, messageChannelSuffix: id.toString());
  }

  @override
  void onNativePlayerCreated(int platformViewId) {
    _controller = TPStreamsPlayerController(platformViewId);
    widget.onPlayerCreated?.call(_controller!);
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }
}
