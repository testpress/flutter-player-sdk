import 'dart:async';
import 'dart:io';

import 'package:tpstreams_player_sdk/generated/native_download_manager_api.g.dart' as native_api;

class TPStreamsDownloadManager {
  final _downloadManagerApi = native_api.NativeDownloadManagerApi();
  final Stream<List<native_api.DownloadAsset>> _downloadsStream =
      native_api.getDownloadsStream().map((event) => event.downloads).asBroadcastStream();

  Future<List<native_api.DownloadAsset>> getAllDownloads() {
    return _downloadManagerApi.getAllDownloads();
  }

  Stream<List<native_api.DownloadAsset>> get downloadsStream {
    return _downloadsStream;
  }

  Future<void> startDownload(String assetId, String? accessToken, [Map<String, String>? metadata]) {
    return _downloadManagerApi.startDownload(assetId, accessToken, metadata);
  }

  Future<void> pauseDownload(native_api.DownloadAsset asset) {
    if (Platform.isIOS) {
      throw UnsupportedError('Pause download is not supported on iOS');
    }
    return _downloadManagerApi.pauseDownload(asset);
  }

  Future<void> cancelDownload(native_api.DownloadAsset asset) {
    return _downloadManagerApi.cancelDownload(asset);
  }

  Future<void> resumeDownload(native_api.DownloadAsset asset) {
    if (Platform.isIOS) {
      throw UnsupportedError('Resume download is not supported on iOS');
    }
    return _downloadManagerApi.resumeDownload(asset);
  }

  Future<void> deleteAllDownloads() {
    return _downloadManagerApi.deleteAllDownloads();
  }

  Future<void> deleteDownload(native_api.DownloadAsset asset) {
    return _downloadManagerApi.deleteDownload(asset);
  }

  dispose() {
    _downloadManagerApi.dispose();
  }
}
