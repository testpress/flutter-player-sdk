import 'package:flutter/material.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk.dart';
import 'screens/downloads_screen.dart';
import 'screens/video_screen.dart';

void main() {
  TPStreamsSDK.initialize(provider: PROVIDER.tpstreams, orgCode: "kyu8rn");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPStreams Player Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final videos = [
      (
        title: 'Watch Video 1',
        assetId: '3Fag3cAA5u4',
        accessToken: 'a47fe426-e9f7-4f59-b93b-c6c88fa3e9e1'
      ),
      (
        title: 'Watch Video 2', 
        assetId: 'BGdPKGKSK7R',
        accessToken: '8af4648b-9949-4b6f-acff-b1ed5e7bd3ec'
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TPStreams Player Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...videos.map((video) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoScreen(
                        assetId: video.assetId,
                        accessToken: video.accessToken,
                        showDownloadOption: true,
                        preferences: TPStreamsPlayerPreferences(
                          enableFullscreen: false,
                          enablePlaybackSpeed: false,
                          enableCaptions: false,
                          showResolutionOptions: false,
                          enableSeekButtons: false,
                          seekBarColor: Colors.blue.value,
                        ),
                      ),
                    ),
                  );
                },
                child: Text(video.title),
              ),
            )),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DownloadsScreen(),
                  ),
                );
              },
              child: const Text('Downloads'),
            ),
          ],
        ),
      ),
    );
  }
}