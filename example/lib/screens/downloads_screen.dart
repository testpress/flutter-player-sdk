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
    _downloadManager.downloadProgressStream.listen(
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

  Color _getStateColor(DownloadState state) {
    switch (state) {
      case DownloadState.notDownloaded:
        return Colors.grey;
      case DownloadState.downloading:
        return Colors.blue;
      case DownloadState.paused:
        return Colors.orange;
      case DownloadState.completed:
        return Colors.green;
      case DownloadState.failed:
        return Colors.red;
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
              child: Text(
                'No downloads available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _downloads.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final asset = _downloads[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              asset.title ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStateColor(asset.state).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStateText(asset.state),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStateColor(asset.state),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (asset.state == DownloadState.downloading) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: asset.progress / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStateColor(asset.state),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(asset.progress).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _downloadManager.dispose();
    super.dispose();
  }
} 