import TPStreamsSDK
import Foundation
import Flutter

class NativeDownloadManager: GetDownloadProgressChangeStreamStreamHandler, NativeDownloadManagerApi, TPStreamsDownloadDelegate {
    private let downloadManager = TPStreamsDownloadManager.shared
    private var eventSink: PigeonEventSink<DownloadProgressChangeEvent>?
    
    init() {
        super.init()
        downloadManager.setTPStreamsDownloadDelegate(tpStreamsDownloadDelegate: self)
    }


    func getAllDownloads() -> [DownloadAsset] {
        return downloadManager.getAllOfflineAssets().map { mapOfflineAssetToDownloadAsset($0) }
    }
    

    override func onListen(withArguments arguments: Any?, sink eventSink: PigeonEventSink<DownloadProgressChangeEvent>) {
        self.eventSink = eventSink
    }
    
    override func onCancel(withArguments arguments: Any?){
        eventSink = nil
    }
    

    func onProgressChange(assetId: String, percentage: Double) {
        notifyDownloadProgress()
    }
    
    func onStateChange(status: Status, offlineAsset: OfflineAsset) {
        notifyDownloadProgress()
    }
    
    func onDelete(assetId: String) {
        notifyDownloadProgress()
    }
    
    func onStart(offlineAsset: OfflineAsset) {
        notifyDownloadProgress()
    }
    
    private func notifyDownloadProgress() {
        let downloadAssets = getAllDownloads()
        let event = DownloadProgressChangeEvent(downloads: downloadAssets)
        eventSink?.success(event)
    }
    
    private func mapOfflineAssetToDownloadAsset(_ asset: OfflineAsset) -> DownloadAsset {
        return DownloadAsset(
            assetId: asset.assetId,
            title: asset.title,
            state: mapDownloadState(Status(rawValue: asset.status)!),
            progress: asset.percentageCompleted
        )
    }
    
    private func mapDownloadState(_ status: Status) -> DownloadState {
        switch status {
        case .inProgress:
            return .downloading
        case .paused:
            return .paused
        case .finished:
            return .completed
        case .failed:
            return .failed
        default:
            return .notDownloaded
        }
    }
    
    func onComplete(offlineAsset: OfflineAsset) {}
    
    func onPause(offlineAsset: OfflineAsset) {}
    
    func onResume(offlineAsset: OfflineAsset) {}
    
    func onCanceled(assetId: String) {}

    func dispose() {
        eventSink?.endOfStream()
        eventSink = nil
    }

    deinit {
        dispose()
    }
}
