import 'package:flutter/material.dart';
import 'package:tpstreams_player_sdk/player_controller.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk.dart';

void main() {
  TPStreamsSDK.initialize(provider: PROVIDER.testpress, orgCode: "lmsdemo");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  late final TPStreamsPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Column(
        children: [
          TPStreamPlayer(
            assetId: "z1TLpfuZzXh",
            accessToken: "5c49285b-0557-4cef-b214-66034d0b77c3",
            onPlayerCreated: _onPlayerCreated,
          ),
          ElevatedButton(
            onPressed: () {
              controller?.pause();
            },
            child: const Text('Pause'),
          ),
        ],
      ),
    ));
  }

  void _onPlayerCreated(TPStreamsPlayerController controller) {
    this.controller = controller;
  }
}
