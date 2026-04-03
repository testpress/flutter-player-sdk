package com.tpstreams.tpstreams_player_sdk

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.fragment.app.FragmentActivity
import androidx.media3.exoplayer.offline.Download
import com.tpstreams.player.download.DownloadClient
import com.tpstreams.player.download.DownloadItem
import io.flutter.plugin.common.BinaryMessenger

class NativeDownloadManager(
    context: Context,
    private val activity: FragmentActivity,
    messenger: BinaryMessenger
) : NativeDownloadManagerApi, GetDownloadsStreamStreamHandler() {
    private val downloadClient = DownloadClient.Companion.getInstance(context)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: PigeonEventSink<DownloadsUpdateEvent>? = null
    private var isListening = false

    private val listener = object : DownloadClient.Listener {
        override fun onDownloadsChanged() {
            notifyDownloadsChange()
        }

        override fun onDownloadStateChanged(downloadItem: DownloadItem, exception: Exception?) {
            notifyDownloadsChange()
        }

        override fun onDownloadStarted(downloadItem: DownloadItem) {
            notifyDownloadsChange()
        }

        override fun onDownloadResumed(downloadItem: DownloadItem) {
            notifyDownloadsChange()
        }

        override fun onDownloadCompleted(downloadItem: DownloadItem) {
            notifyDownloadsChange()
        }

        override fun onDownloadFailed(downloadItem: DownloadItem, error: Exception) {
            notifyDownloadsChange()
        }

        override fun onDownloadDeleted(assetId: String) {
            notifyDownloadsChange()
        }
    }

    init {
        register(messenger, this)
    }

    override fun getAllDownloads(): List<DownloadAsset> {
        return downloadClient.getAllDownloadItems().map {
            mapDownloadItemToDownloadAsset(it)
        }
    }

    override fun startDownload(assetId: String, accessToken: String, metadata: Map<String, String>?) {
        downloadClient.startDownload(activity, assetId, accessToken, null, metadata ?: emptyMap())
        notifyDownloadsChange()
    }

    override fun cancelDownload(asset: DownloadAsset) {
        downloadClient.removeDownload(asset.assetId)
        notifyDownloadsChange()
    }

    override fun resumeDownload(asset: DownloadAsset) {
        downloadClient.resumeDownload(asset.assetId)
        notifyDownloadsChange()
    }

    override fun deleteDownload(asset: DownloadAsset) {
        downloadClient.removeDownload(asset.assetId)
        notifyDownloadsChange()
    }

    override fun pauseDownload(asset: DownloadAsset) {
        downloadClient.pauseDownload(asset.assetId)
        notifyDownloadsChange()
    }

    override fun deleteAllDownloads() {
        downloadClient.getAllDownloadItems().forEach { item ->
            downloadClient.removeDownload(item.assetId)
        }
        notifyDownloadsChange()
    }

    override fun onListen(p0: Any?, sink: PigeonEventSink<DownloadsUpdateEvent>) {
        eventSink = sink
        if (!isListening) {
            downloadClient.addListener(listener)
            isListening = true
        }
        notifyDownloadsChange()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopListening()
    }

    override fun dispose() {
        stopListening()
        eventSink?.endOfStream()
        eventSink = null
    }

    private fun notifyDownloadsChange() {
        mainHandler.post {
            eventSink?.success(DownloadsUpdateEvent(getAllDownloads()))
        }
    }

    private fun stopListening() {
        if (isListening) {
            downloadClient.removeListener(listener)
            isListening = false
        }
    }

    private fun mapDownloadItemToDownloadAsset(
        item: DownloadItem
    ): DownloadAsset {
        val computedProgress = if (item.totalBytes > 0L) {
            ((item.downloadedBytes.toDouble() / item.totalBytes.toDouble()) * 100.0).coerceIn(0.0, 100.0)
        } else {
            item.progressPercentage.toDouble().coerceIn(0.0, 100.0)
        }

        return DownloadAsset(
            assetId = item.assetId,
            title = item.title,
            state = mapDownloadState(item.state),
            progress = computedProgress,
            metadata = item.metadata ?: emptyMap()
        )
    }

    private fun mapDownloadState(state: Int): DownloadState {
        return when (state) {
            Download.STATE_DOWNLOADING, Download.STATE_QUEUED, Download.STATE_RESTARTING -> DownloadState.DOWNLOADING
            Download.STATE_COMPLETED -> DownloadState.COMPLETED
            Download.STATE_FAILED -> DownloadState.FAILED
            Download.STATE_STOPPED -> DownloadState.PAUSED
            else -> DownloadState.NOT_DOWNLOADED
        }
    }
}
