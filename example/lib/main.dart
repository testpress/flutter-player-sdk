import 'package:flutter/material.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk.dart';
import 'screens/downloads_screen.dart';
import 'screens/video_screen.dart';

void main() {
  TPStreamsSDK.initialize(provider: PROVIDER.tpstreams, orgCode: "6eafqn");

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('TPStreams Player Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoScreen(
                      assetId: '8eaHZjXt6km',
                      accessToken: '16b608ba-9979-45a0-94fb-b27c1a86b3c1',
                      showDownloadOption: true,
                    ),
                  ),
                );
              },
              child: const Text('Watch Video 1'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoScreen(
                      assetId: '68PAFnYTjSU',
                      accessToken: '5f3ded52-ace8-487e-809c-10de895872d6',
                      showDownloadOption: true,
                    ),
                  ),
                );
              },
              child: const Text('Watch Video 2'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DownloadsScreen(),
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
