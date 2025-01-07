import 'dart:async';

import 'package:tpstreams_player_sdk/generated/native_download_manager_api.g.dart' as native_api;

class TPStreamsDownloadManager {
  final _downloadManagerApi = native_api.NativeDownloadManagerApi();

  Future<List<native_api.DownloadAsset>> getAllDownloads() {
    return _downloadManagerApi.getAllDownloads();
  }

  Stream<List<native_api.DownloadAsset>> getDownloadProgressChangeStream() {
    return native_api.getDownloadProgressChangeStream().map((event) => event.downloads);
  }

  dispose() {
    _downloadManagerApi.dispose();
  }
} 