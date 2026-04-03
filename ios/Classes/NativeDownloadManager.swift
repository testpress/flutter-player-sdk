import TPStreamsSDK
import Foundation
import Flutter
import UIKit

class NativeDownloadManager: GetDownloadsStreamStreamHandler, NativeDownloadManagerApi, TPStreamsDownloadDelegate {
    private let downloadManager = TPStreamsDownloadManager.shared
    private var eventSink: PigeonEventSink<DownloadsUpdateEvent>?
    private var pollTimer: Timer?
    private let pollInterval: TimeInterval = 1.0
    
    override init() {
        super.init()
        downloadManager.setTPStreamsDownloadDelegate(tpStreamsDownloadDelegate: self)
    }


    func getAllDownloads() -> [DownloadAsset] {
        return downloadManager.getAllOfflineAssets().map { mapOfflineAssetToDownloadAsset($0) }
    }
    
    func startDownload(assetId: String, accessToken: String, metadata: [String: String]?) throws {
        let metadataAny = metadata?.reduce(into: [String: Any]()) { partialResult, entry in
            partialResult[entry.key] = entry.value
        }

        downloadManager.startDownload(
            assetID: assetId,
            accessToken: accessToken,
            metadata: metadataAny,
            presentingViewController: topViewController()
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.notifyDownloadsChange()
            }
        }

        notifyDownloadsChange()
    }
    
    func cancelDownload(asset: DownloadAsset) throws {
        downloadManager.cancelDownload(asset.assetId)
        notifyDownloadsChange()
    }
    
    func resumeDownload(asset: DownloadAsset) throws {
        downloadManager.resumeDownload(asset.assetId)
        notifyDownloadsChange()
    }
    
    func deleteDownload(asset: DownloadAsset) throws {
        downloadManager.deleteDownload(asset.assetId)
        notifyDownloadsChange()
    }
    
    func pauseDownload(asset: DownloadAsset) throws {
        downloadManager.pauseDownload(asset.assetId)
        notifyDownloadsChange()
    }
    
    func deleteAllDownloads() throws {
        getAllDownloads().forEach { downloadManager.deleteDownload($0.assetId) }
        notifyDownloadsChange()
    }
    

    override func onListen(withArguments arguments: Any?, sink eventSink: PigeonEventSink<DownloadsUpdateEvent>) {
        self.eventSink = eventSink
        startPolling()
        notifyDownloadsChange()
    }
    
    override func onCancel(withArguments arguments: Any?){
        stopPolling()
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
    
    func onPause(offlineAsset: OfflineAsset) {
        notifyDownloadsChange()
    }
    
    func onResume(offlineAsset: OfflineAsset) {
        notifyDownloadsChange()
    }
    
    func onCanceled(assetId: String) {
        notifyDownloadsChange()
    }

    func dispose() {
        stopPolling()
        eventSink?.endOfStream()
        eventSink = nil
    }

    private func startPolling() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.notifyDownloadsChange()
        }
        if let pollTimer {
            RunLoop.main.add(pollTimer, forMode: .common)
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let rootController: UIViewController?
        if let base {
            rootController = base
        } else {
            if #available(iOS 13.0, *) {
                rootController = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first(where: { $0.isKeyWindow })?
                    .rootViewController
            } else {
                rootController = UIApplication.shared.keyWindow?.rootViewController
            }
        }

        if let navigationController = rootController as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }

        if let tabBarController = rootController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return topViewController(base: selectedViewController)
        }

        if let presentedViewController = rootController?.presentedViewController {
            return topViewController(base: presentedViewController)
        }

        return rootController
    }

    deinit {
        dispose()
    }
}
