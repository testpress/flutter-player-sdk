import 'package:flutter/material.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk.dart';


void main() { 
  TPStreamsSDK.initialize(provider: PROVIDER.testpress, orgCode: "lmsdemo");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: const TPStreamPlayer(
          assetId: "z1TLpfuZzXh", 
          accessToken: "5c49285b-0557-4cef-b214-66034d0b77c3"
        )
      ),
    );
  }
}
