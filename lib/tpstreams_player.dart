import 'package:flutter/foundation.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tpstreams_player_sdk/player_controller.dart';
import 'package:tpstreams_player_sdk/generated/player_preferences.g.dart';

import 'generated/native_player_listeners.g.dart';
import 'generated/native_player_api.g.dart';


class TPStreamPlayer extends StatefulWidget {
  final String assetId;
  final String? accessToken;
  final double aspectRatio;
  final Function(TPStreamsPlayerController controller)? onPlayerCreated;
  final bool? showDownloadOption;
  final bool? startInFullscreen;
  final int? offlineLicenseExpireDays;
  final bool _isOfflinePlayback;
  final Map<String, String>? metadata;
  final TPStreamsPlayerPreferences preferences;
  final bool autoPlay;

  TPStreamPlayer({
    super.key,
    required this.assetId,
    required this.accessToken,
    this.aspectRatio = 16 / 9,
    this.onPlayerCreated,
    this.showDownloadOption = false,
    this.startInFullscreen = false,
    this.offlineLicenseExpireDays = 15,
    this.metadata,
    this.autoPlay = true,
    TPStreamsPlayerPreferences? preferences,
  }) : _isOfflinePlayback = false,
       preferences = preferences ?? TPStreamsPlayerPreferences(
           enableFullscreen: true,
           enablePlaybackSpeed: true,
           enableCaptions: true,
           showResolutionOptions: true,
           enableSeekButtons: true,
       );

  TPStreamPlayer.offline({
    super.key,
    required String assetId,
    this.aspectRatio = 16 / 9,
    this.onPlayerCreated,
    this.autoPlay = true,
  }) : assetId = assetId,
       accessToken = null,
       showDownloadOption = false,
       startInFullscreen = false,
       offlineLicenseExpireDays = 15,
       _isOfflinePlayback = true,
       metadata = null,
       preferences = TPStreamsPlayerPreferences(
           enableFullscreen: true,
           enablePlaybackSpeed: true,
           enableCaptions: true,
           showResolutionOptions: true,
           enableSeekButtons: true,
       );

  @override
  State<TPStreamPlayer> createState() => _TPStreamPlayerState();
}

class _TPStreamPlayerState extends State<TPStreamPlayer> implements NativePlayerInitializationListener {
  TPStreamsPlayerController? _controller;
  int? _platformViewId;
  bool _isPlayerCreated = false;
  late NativePlayerApi _nativeApi;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: _buildPlatformView(),
        ),
      ),
    );
  }

  Widget _buildPlatformView() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildAndroidView();
      case TargetPlatform.iOS:
        return _buildIOSView();
      default:
        return Text('$defaultTargetPlatform is not yet supported by the web_view plugin');
    }
  }

  Widget _buildAndroidView() {
    return PlatformViewLink(
      viewType: 'tpstreams_player_sdk/player_view',
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: 'tpstreams_player_sdk/player_view',
          layoutDirection: TextDirection.ltr,
          creationParams: _creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        )..addOnPlatformViewCreatedListener(
            _onAndroidPlatformViewCreated(params.onPlatformViewCreated));
      },
    );
  }

  Widget _buildIOSView() {
    return UiKitView(
      viewType: 'tpstreams_player_sdk/player_view',
      creationParams: _creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: setUpNativePlayerInitializationListener,
    );
  }

  Map<String, dynamic> get _creationParams => {
    "assetId": widget.assetId,
    "accessToken": widget.accessToken,
    "isOfflinePlayback": widget._isOfflinePlayback,
    "showDownloadOption": widget.showDownloadOption,
    "startInFullscreen": widget.startInFullscreen,
    "offlineLicenseExpireDays": widget.offlineLicenseExpireDays,
    "autoPlay": widget.autoPlay,
    if (widget.metadata != null) "metadata": widget.metadata,
    "playerPreferences": widget.preferences.encode(),
  };

  void Function(int id) _onAndroidPlatformViewCreated(Function platformViewCreatedCallback) {
    return (id) {
      setUpNativePlayerInitializationListener(id);
      platformViewCreatedCallback(id);
    };
  }

  void setUpNativePlayerInitializationListener(int id) {
    _platformViewId = id;
    _nativeApi = NativePlayerApi(messageChannelSuffix: id.toString());
    NativePlayerInitializationListener.setUp(this, messageChannelSuffix: id.toString());
  }

  @override
  void onNativePlayerCreated(int platformViewId) {
    _controller = TPStreamsPlayerController(platformViewId);
    _isPlayerCreated = true;
    widget.onPlayerCreated?.call(_controller!);
  }

  @override
  void dispose() {
    final viewId = _platformViewId;
    if (viewId != null) {
      if (_isPlayerCreated) {
        _controller!.dispose();
      } else {
        _nativeApi.dispose();
      }
    }

    super.dispose();
  }
}
