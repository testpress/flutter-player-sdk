package com.tpstreams.tpstreams_player_sdk

import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.tpstream.player.data.source.local.DownloadStatus
import com.tpstream.player.offline.TpStreamDownloadManager
import androidx.lifecycle.Observer
import com.tpstream.player.TpInitParams
import com.tpstream.player.data.Asset
import io.flutter.plugin.common.BinaryMessenger

class NativeDownloadManager(
    context: Context,
    private val activity: FragmentActivity,
    messenger: BinaryMessenger
) : NativeDownloadManagerApi, GetDownloadsStreamStreamHandler() {
    private val downloadManager = TpStreamDownloadManager(context)
    private val downloads = downloadManager.getAllDownloads()
    private var eventSink: PigeonEventSink<DownloadsUpdateEvent>? = null
    
    private val downloadObserver = Observer<List<Asset>?> { assets ->
        assets?.let { notifyDownloadsChange(it) }
    }

    init {
        downloads.observeForever(downloadObserver)
        register(messenger, this)
    }

    override fun getAllDownloads(): List<DownloadAsset> {
        return downloads.value?.map { asset ->
            mapAssetToDownloadAsset(asset)
        } ?: emptyList()
    }

    override fun startDownload(assetId: String, accessToken: String) {
        val parameters = TpInitParams.Builder()
            .setVideoId(assetId)
            .setAccessToken(accessToken)
            .build()

        downloadManager.startDownload(activity, parameters)
    }

    override fun cancelDownload(asset: DownloadAsset) {
        findAsset(asset.assetId)?.let { downloadManager.cancelDownload(it) }
    }

    override fun resumeDownload(asset: DownloadAsset) {
        findAsset(asset.assetId)?.let { downloadManager.resumeDownload(it) }
    }

    override fun deleteDownload(asset: DownloadAsset) {
        findAsset(asset.assetId)?.let { downloadManager.deleteDownload(it) }
    }

    override fun pauseDownload(asset: DownloadAsset) {
        findAsset(asset.assetId)?.let { downloadManager.pauseDownload(it) }
    }

    private fun findAsset(assetId: String): Asset? {
        return downloads.value?.find { it.id == assetId }
    }

    override fun deleteAllDownloads() {
        downloadManager.deleteAllDownloads()
    }

    override fun onListen(p0: Any?, sink: PigeonEventSink<DownloadsUpdateEvent>) {
        downloads.observeForever(downloadObserver)
        eventSink = sink
    }

    override fun onCancel(arguments: Any?) {
        downloads.removeObserver(downloadObserver)
        eventSink = null
    }

    override fun dispose() {
        downloads.removeObserver(downloadObserver)
        eventSink?.endOfStream()
        eventSink = null
    }

    private fun notifyDownloadsChange(assets: List<Asset>) {
        val downloadAssets = assets.map { asset ->
            mapAssetToDownloadAsset(asset)
        }
        eventSink?.success(DownloadsUpdateEvent(downloadAssets))
    }

    private fun mapAssetToDownloadAsset(asset: Asset): DownloadAsset {
        return DownloadAsset(
            assetId = asset.id,
            title = asset.title,
            state = mapDownloadState(asset.video.downloadState),
            progress = asset.video.percentageDownloaded.toDouble(),
            metadata = asset.metadata
        )
    }

    private fun mapDownloadState(nativeState: DownloadStatus?): DownloadState = when (nativeState) {
        DownloadStatus.DOWNLOADING -> DownloadState.DOWNLOADING
        DownloadStatus.PAUSE -> DownloadState.PAUSED
        DownloadStatus.COMPLETE -> DownloadState.COMPLETED
        DownloadStatus.FAILED -> DownloadState.FAILED
        else -> DownloadState.NOT_DOWNLOADED
    }
}
