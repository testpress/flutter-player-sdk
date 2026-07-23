import 'package:flutter/material.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VideoScreen extends StatefulWidget {
  final String assetId;
  final String accessToken;
  final bool showDownloadOption;
  final bool autoPlay;

  const VideoScreen({
    super.key,
    required this.assetId,
    required this.accessToken,
    this.showDownloadOption = false,
    this.autoPlay = true,
    this.preferences,
  });

  final TPStreamsPlayerPreferences? preferences;

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late TPStreamsPlayerController _controller;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  final _downloadManager = TPStreamsDownloadManager();

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
              autoPlay: widget.autoPlay,
              preferences: widget.preferences,
              onPlayerCreated: (controller) {
                _controller = controller;
                _controller.setMaxResolution(240);
                _controller.enableAutoFullscreenOnRotate();
                _controller.setWatermarks([
                  WatermarkConfig(
                    text: '© testpress',
                    x: 100,
                    y: 50,
                    opacity: 0.9,
                    animation: WatermarkAnimation(
                      type: WatermarkAnimationType.pingPong,
                      duration: 1000,
                    ),
                  ),
                  WatermarkConfig(
                    text: '© TPStreams',
                    x: 0,
                    y: 50,
                    opacity: 0.3,
                    animation: WatermarkAnimation(
                      type: WatermarkAnimationType.pingPong,
                      duration: 5000,
                    ),
                  ),
                ]);
                _controller.onBeforeFullScreenEnter = () {
                  print('Will enter fullscreen');
                };

                _controller.onBeforeFullScreenExit = () {
                  print('Will exit fullscreen');
                };

                _controller.onAccessTokenExpired = (String videoId) async {
                  String newToken = "Token"; //await getNewToken();
                  return newToken;
                };

                _controller.onReplay = () {
                  Fluttertoast.showToast(msg: 'Replay button clicked');
                };

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
              if (widget.showDownloadOption) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _downloadManager.startDownload(
                      widget.assetId,
                      widget.accessToken,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Download started'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _controller.enterFullScreen();  
                  },
                  child: const Text('Enter Fullscreen'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _onPlayerValueChanged() {
    final newIsPlaying = _controller.value.isPlaying;
    final newIsFullScreen = _controller.value.isFullScreen;
    
    if (newIsPlaying != _isPlaying) {
      setState(() {
        _isPlaying = newIsPlaying;
      });
    }
    
    if (newIsFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = newIsFullScreen;
      });
      
      if (newIsFullScreen) {
        Fluttertoast.showToast(
          msg: "Entering Fullscreen",
        );
      } else {
        Fluttertoast.showToast(
          msg: "Exiting Fullscreen",
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerValueChanged);
    super.dispose();
  }
}
