import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TPStreamPlayer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          color: Colors.black,
          child: AspectRatio(
            aspectRatio: aspectRatio, 
            child: getPlayerNativeView()
          ),
    ));
  }

  Widget getPlayerNativeView() {
    var creationParams = {"assetId": assetId, "accessToken": accessToken};

    switch (defaultTargetPlatform) {
      
      case TargetPlatform.android:
        return AndroidView(
          viewType: 'tpstreams_player_sdk/player_view',
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.iOS:
        return UiKitView(
            viewType: 'tpstreams_player_sdk/player_view',
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
          );
      default:
        return Text(
            '$defaultTargetPlatform is not yet supported by the web_view plugin');
    }
  }
}
