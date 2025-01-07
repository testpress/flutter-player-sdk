import 'package:flutter/material.dart';
import 'package:tpstreams_player_sdk/tpstreams_player_sdk.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final _downloadManager = TPStreamsDownloadManager();
  List<DownloadAsset> _downloads = [];

  @override
  void initState() {
    super.initState();
    _loadDownloads();
    _listenToDownloadProgress();
  }

  void _loadDownloads() async {
    final downloads = await _downloadManager.getAllDownloads();
    setState(() {
      _downloads = downloads;
    });
  }

  void _listenToDownloadProgress() {
    _downloadManager.getDownloadProgressChangeStream().listen(
      (downloads) {
        setState(() {
          _downloads = downloads;
        });
      },
      onError: (error) {
        debugPrint('Download progress error: $error');
      },
    );
  }

  String _getStateText(DownloadState state) {
    switch (state) {
      case DownloadState.notDownloaded:
        return 'Not Downloaded';
      case DownloadState.downloading:
        return 'Downloading';
      case DownloadState.paused:
        return 'Paused';
      case DownloadState.completed:
        return 'Completed';
      case DownloadState.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
      ),
      body: _downloads.isEmpty
          ? const Center(
              child: Text('No downloads available'),
            )
          : ListView.builder(
              itemCount: _downloads.length,
              itemBuilder: (context, index) {
                final asset = _downloads[index];
                return ListTile(
                  title: Text(asset.title ?? 'Untitled'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getStateText(asset.state)),
                      if (asset.state == DownloadState.downloading)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            value: asset.progress / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      if (asset.state == DownloadState.downloading)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('${asset.progress.toStringAsFixed(1)}%'),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
} 