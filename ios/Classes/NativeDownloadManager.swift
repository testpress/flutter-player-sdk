import TPStreamsSDK
import Foundation
import Flutter
import UIKit

class NativeDownloadManager: GetDownloadsStreamStreamHandler, NativeDownloadManagerApi, TPStreamsDownloadDelegate {
    private let downloadManager = TPStreamsDownloadManager.shared
    private var eventSink: PigeonEventSink<DownloadsUpdateEvent>?
    
    override init() {
        super.init()
        downloadManager.setTPStreamsDownloadDelegate(tpStreamsDownloadDelegate: self)
    }


    func getAllDownloads() -> [DownloadAsset] {
        return downloadManager.getAllOfflineAssets().map { mapOfflineAssetToDownloadAsset($0) }
    }
    
    func startDownload(assetId: String, accessToken: String?, metadata: [String: String]?) throws {
        let topVc = getTopMostViewController()

        downloadManager.startDownload(
            assetID: assetId,
            accessToken: accessToken,
            metadata: metadata,
            presentingViewController: topVc
        )
    }
    
    func cancelDownload(asset: DownloadAsset) throws {
        downloadManager.cancelDownload(asset.assetId)
    }
    
    func resumeDownload(asset: DownloadAsset) throws {
        downloadManager.resumeDownload(asset.assetId)
    }
    
    func deleteDownload(asset: DownloadAsset) throws {
        downloadManager.deleteDownload(asset.assetId)
    }
    
    func pauseDownload(asset: DownloadAsset) throws {
        downloadManager.pauseDownload(asset.assetId)
    }
    
    func deleteAllDownloads() throws {
        getAllDownloads().forEach { downloadManager.deleteDownload($0.assetId) }
    }
    

    override func onListen(withArguments arguments: Any?, sink eventSink: PigeonEventSink<DownloadsUpdateEvent>) {
        self.eventSink = eventSink
    }
    
    override func onCancel(withArguments arguments: Any?){
        eventSink = nil
    }
    

    func onProgressChange(assetId: String, percentage: Double) {
        notifyDownloadsChange()
    }
    
    func onStateChange(status: Status, offlineAsset: OfflineAsset) {
        notifyDownloadsChange()
    }
    
    func onDelete(assetId: String) {
        notifyDownloadsChange()
    }
    
    func onStart(offlineAsset: OfflineAsset) {
        notifyDownloadsChange()
    }
    
    private func notifyDownloadsChange() {
        let downloadAssets = getAllDownloads()
        let event = DownloadsUpdateEvent(downloads: downloadAssets)
        eventSink?.success(event)
    }
    
    private func mapOfflineAssetToDownloadAsset(_ asset: OfflineAsset) -> DownloadAsset {
        // Convert metadata from [String: Any]? to [String: String]?
        // Filter out non-string values and nil keys/values
        let metadata: [String: String]? = asset.metadata?.compactMapValues { value in
            return value as? String
        }
        
        return DownloadAsset(
            assetId: asset.assetId,
            title: asset.title,
            state: mapDownloadState(Status(rawValue: asset.status)!),
            progress: asset.percentageCompleted,
            metadata: metadata
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
    
    func onCanceled(assetId: String) {
        notifyDownloadsChange()
    }

    func dispose() {
        eventSink?.endOfStream()
        eventSink = nil
    }

    private func getTopMostViewController() -> UIViewController? {
        var topVc = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow })?.rootViewController

        while let current = topVc {
            if let nav = current as? UINavigationController {
                topVc = nav.visibleViewController
            } else if let tab = current as? UITabBarController {
                topVc = tab.selectedViewController
            } else if let presented = current.presentedViewController {
                topVc = presented
            } else {
                break
            }
        }
        return topVc
    }

    deinit {
        dispose()
    }
}
