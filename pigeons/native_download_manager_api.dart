import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/native_download_manager_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/com/tpstreams/tpstreams_player_sdk/generated/NativeDownloadManagerApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.tpstreams.tpstreams_player_sdk',
    includeErrorClass: false,
  ),
  swiftOut: 'ios/Classes/generated/NativeDownloadManagerApi.g.swift',
  swiftOptions: SwiftOptions(
    includeErrorClass: false
  ),
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

  DownloadAsset({
    required this.assetId,
    this.title,
    required this.state,
    required this.progress
  });
}

class DownloadProgressChangeEvent {
  final List<DownloadAsset> downloads;

  DownloadProgressChangeEvent({
    required this.downloads,
  });
}

@HostApi()
abstract class NativeDownloadManagerApi {
  List<DownloadAsset> getAllDownloads();
  void dispose();
}

@EventChannelApi()
abstract class DownloadProgressApi {
  DownloadProgressChangeEvent getDownloadProgressChangeStream();
}