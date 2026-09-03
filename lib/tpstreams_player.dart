import 'package:flutter/foundation.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tpstreams_player_sdk/player_controller.dart';
import 'package:tpstreams_player_sdk/generated/player_preferences.g.dart';

import 'generated/native_player_listeners.g.dart';
import 'generated/native_player_api.g.dart';
import 'src/device_capability.dart';


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
  final int? resolution;
  final String? userId;

  TPStreamPlayer({
    super.key,
    required this.assetId,
    this.accessToken,
    this.aspectRatio = 16 / 9,
    this.onPlayerCreated,
    this.showDownloadOption = false,
    this.startInFullscreen = false,
    this.offlineLicenseExpireDays = 15,
    this.metadata,
    this.autoPlay = true,
    this.resolution,
    this.userId,
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
    this.userId,
    Map<String, String>? metadata,
  }) : assetId = assetId,
       accessToken = null,
       showDownloadOption = false,
       startInFullscreen = false,
       offlineLicenseExpireDays = 15,
       _isOfflinePlayback = true,
       metadata = metadata,
       resolution = null,
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
  late Future<String?> _widevineFuture;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android) {
      _widevineFuture = DeviceCapability.instance.getWidevineLevel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_controller?.value.isFullScreen ?? false) {
          _controller?.exitFullScreen();
          return false;
        }
        return true;
      },
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
    final cachedLevel = DeviceCapability.instance.widevineLevel;
    if (cachedLevel != null) {
      return _buildAndroidPlatformView(isL3: cachedLevel == 'L3');
    }

    return FutureBuilder<String?>(
      future: _widevineFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.expand(
            child: ColoredBox(color: Colors.black),
          );
        }

        return _buildAndroidPlatformView(isL3: snapshot.data == 'L3');
      },
    );
  }

  Widget _buildAndroidPlatformView({required bool isL3}) {
    final params = _getCreationParams(useTextureMode: isL3);

    return PlatformViewLink(
      viewType: 'tpstreams_player_sdk/player_view',
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (viewParams) {
        if (isL3) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: viewParams.id,
            viewType: 'tpstreams_player_sdk/player_view',
            layoutDirection: TextDirection.ltr,
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
          )
            ..addOnPlatformViewCreatedListener(
                _onAndroidPlatformViewCreated(viewParams.onPlatformViewCreated))
            ..create();
        } else {
          return PlatformViewsService.initExpensiveAndroidView(
            id: viewParams.id,
            viewType: 'tpstreams_player_sdk/player_view',
            layoutDirection: TextDirection.ltr,
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
          )
            ..addOnPlatformViewCreatedListener(
                _onAndroidPlatformViewCreated(viewParams.onPlatformViewCreated));
        }
      },
    );
  }

  Widget _buildIOSView() {
    return UiKitView(
      viewType: 'tpstreams_player_sdk/player_view',
      creationParams: _getCreationParams(),
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: setUpNativePlayerInitializationListener,
    );
  }

  Map<String, dynamic> _getCreationParams({bool useTextureMode = false}) => {
    "assetId": widget.assetId,
    "accessToken": widget.accessToken,
    "isOfflinePlayback": widget._isOfflinePlayback,
    "showDownloadOption": widget.showDownloadOption,
    "startInFullscreen": widget.startInFullscreen,
    "offlineLicenseExpireDays": widget.offlineLicenseExpireDays,
    "autoPlay": widget.autoPlay,
    "useTextureMode": useTextureMode,
    if (widget.metadata != null) "metadata": widget.metadata,
    if (widget.resolution != null) "resolution": widget.resolution,
    if (widget.userId != null) "userId": widget.userId,
    "playerPreferences": widget.preferences.encode(),
  };

  void Function(int id) _onAndroidPlatformViewCreated(Function platformViewCreatedCallback) {
    return (id) {
      setUpNativePlayerInitializationListener(id);
      platformViewCreatedCallback(id);
    };
  }

  bool _isDisposed = false;

  void setUpNativePlayerInitializationListener(int id) {
    if (_isDisposed) {
      NativePlayerApi(messageChannelSuffix: id.toString()).dispose();
      return;
    }
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
    _isDisposed = true;
    final viewId = _platformViewId;
    if (viewId != null) {
      NativePlayerInitializationListener.setUp(null, messageChannelSuffix: viewId.toString());
      if (_isPlayerCreated) {
        _controller!.dispose();
      } else {
        _nativeApi.dispose();
      }
    }

    super.dispose();
  }
}


typedef TestpressPlayer = TPStreamPlayer;
