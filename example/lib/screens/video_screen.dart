import 'package:flutter/material.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk.dart';

class VideoScreen extends StatefulWidget {
  final String assetId;
  final String accessToken;
  final bool showDownloadOption;

  const VideoScreen({
    super.key,
    required this.assetId,
    required this.accessToken,
    this.showDownloadOption = false,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late TPStreamsPlayerController _controller;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: TPStreamPlayer(
              assetId: widget.assetId,
              accessToken: widget.accessToken,
              showDownloadOption: widget.showDownloadOption,
              onPlayerCreated: (controller) {
                _controller = controller;
                // Listen to player value changes
                _controller.addListener(_onPlayerValueChanged);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 32,
                onPressed: () {
                  if (_isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onPlayerValueChanged() {
    final newIsPlaying = _controller.value.isPlaying;
    if (newIsPlaying != _isPlaying) {
      setState(() {
        _isPlaying = newIsPlaying;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerValueChanged);
    super.dispose();
  }
} 