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
    title: 'Video 1 - 3Fag3cAA5u4',
    assetId: '3Fag3cAA5u4',
    accessToken: 'a47fe426-e9f7-4f59-b93b-c6c88fa3e9e1'
  ),
  (
    title: 'Video 2 - BGdPKGKSK7R',
    assetId: 'BGdPKGKSK7R',
    accessToken: '8af4648b-9949-4b6f-acff-b1ed5e7bd3ec'
  ),
  (
    title: 'Video 3 - 9CZkRyABbxC',
    assetId: '9CZkRyABbxC',
    accessToken: 'd2f5c8f0-998b-40ab-8baa-adec513c296a'
  ),
  (
    title: 'Video 4 - qGTApRERn4P',
    assetId: 'qGTApRERn4P',
    accessToken: 'ce3d90b5-e89d-4f48-aebc-b71e68f1312d'
  ),
  (
    title: 'Video 5 - 86gaXq9FEpF',
    assetId: '86gaXq9FEpF',
    accessToken: '704257cc-727a-4016-9a7f-7f9cc3e225db'
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
                          enableFullscreen: true,
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