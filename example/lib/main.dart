import 'package:flutter/material.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk.dart';
import 'screens/downloads_screen.dart';
import 'screens/video_screen.dart';

void main() {
  TPStreamsSDK.initialize(provider: PROVIDER.tpstreams, orgCode: "9q94nm");

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
        assetId: '57gHcHDBxKX',
        accessToken: '5e28479d-69d8-41c7-9664-79b7eb8f1f95',
        resolution: '260p',

      ),
      (
        title: 'Watch Video 2', 
        assetId: '4P3nJXp2xFT',
        accessToken: 'cde2c1a6-434d-4fd1-99f4-9e2024bf2576',
        resolution: '720p',
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
            ElevatedButton(
              onPressed: () {
                final downloadManager = TPStreamsDownloadManager();
                downloadManager.startDownload(
                  videos[0].assetId,
                  videos[0].accessToken,
                  null,
                  videos[0].resolution,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download started'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Start Download via API'),
            ),
          ],
        ),
      ),
    );
  }
}
