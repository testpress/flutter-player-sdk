import TPStreamsSDK

class NativeDownloadManager: NativeDownloadManagerApi, TPStreamsDownloadDelegate, GetDownloadProgressChangeStreamStreamHandler {
    private let downloadManager = TPStreamsDownloadManager.shared
    private var eventSink: FlutterEventSink?
    
    init(messenger: FlutterBinaryMessenger) {
        super.init()
        downloadManager.setTPStreamsDownloadDelegate(tpStreamsDownloadDelegate: self)
        GetDownloadProgressChangeStreamStreamHandler.register(messenger: messenger, streamHandler: self)
    }

    // MARK: - NativeDownloadManagerApi Implementation
    func getAllDownloads() -> [DownloadAsset] {
        return downloadManager.getAllOfflineAssets().map { mapOfflineAssetToDownloadAsset($0) }
    }
    
    // MARK: - Stream Handler Implementation
    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    // MARK: - TPStreamsDownloadDelegate Implementation
    func onProgressChange(assetId: String, percentage: Double) {
        notifyDownloadProgress()
    }
    
    func onStateChange(status: Status, offlineAsset: OfflineAsset) {
        notifyDownloadProgress()
    }
    
    // MARK: - Helper Methods
    private func notifyDownloadProgress() {
        let assets = downloadManager.getAllOfflineAssets()
        let downloadAssets = assets.map { mapOfflineAssetToDownloadAsset($0) }
        let event = DownloadProgressChangeEvent(downloads: downloadAssets)
        eventSink?(event)
    }
    
    private func mapOfflineAssetToDownloadAsset(_ asset: OfflineAsset) -> DownloadAsset {
        return DownloadAsset(
            assetId: asset.assetId,
            title: asset.title,
            state: mapDownloadState(asset.status),
            progress: asset.downloadProgress
        )
    }
    
    private func mapDownloadState(_ status: Status) -> DownloadState {
        switch status {
        case .downloading:
            return .downloading
        case .paused:
            return .paused
        case .completed:
            return .completed
        case .failed:
            return .failed
        default:
            return .notDownloaded
        }
    }

    func dispose() {
        eventSink?.endOfStream()
        eventSink = nil
    }

    

    deinit {
        dispose()
    }
}
