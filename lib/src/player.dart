class TPStreamsPlayer extends StatefulWidget {
  final String assetId;
  final String? accessToken;
  final bool isOfflinePlayback;
  final Function(TPStreamsPlayerController)? onPlayerCreated;

  const TPStreamsPlayer({
    super.key,
    required this.assetId,
    this.accessToken,
    this.isOfflinePlayback = false,
    this.onPlayerCreated,
  }) : assert(
         isOfflinePlayback || accessToken != null,
         'accessToken is required for online playback',
       );
}