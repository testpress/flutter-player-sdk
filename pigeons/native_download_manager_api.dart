import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/native_download_manager_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/src/main/kotlin/com/tpstreams/tpstreams_player_sdk/generated/NativeDownloadManagerApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.tpstreams.tpstreams_player_sdk',
    includeErrorClass: false,
  ),
  swiftOut: 'ios/Classes/generated/NativeDownloadManagerApi.g.swift',
  swiftOptions: SwiftOptions(includeErrorClass: false),
))
enum DownloadState {
  notDownloaded,
  downloading,
  paused,
  completed,
  failed,
}

class DownloadAsset {
  final String assetId;
  final String? title;
  final DownloadState state;
  final double progress;
  final int totalSize;
  final int downloadedSize;
  final String? thumbnailUrl;
  final Map<String, String>? metadata;

  DownloadAsset({
    required this.assetId,
    this.title,
    required this.state,
    required this.progress,
    required this.totalSize,
    required this.downloadedSize,
    this.thumbnailUrl,
    this.metadata,
  });
}

class DownloadsUpdateEvent {
  final List<DownloadAsset> downloads;

  DownloadsUpdateEvent({
    required this.downloads,
  });
}

@HostApi()
abstract class NativeDownloadManagerApi {
  List<DownloadAsset> getAllDownloads();
  void startDownload(String assetId, String? accessToken,
      Map<String, String>? metadata, String? resolution);
  void cancelDownload(DownloadAsset asset);
  void resumeDownload(DownloadAsset asset);
  void deleteDownload(DownloadAsset asset);
  void pauseDownload(DownloadAsset asset);
  void deleteAllDownloads();
  void dispose();
}

@EventChannelApi()
abstract class DownloadStreamApi {
  DownloadsUpdateEvent getDownloadsStream();
}
