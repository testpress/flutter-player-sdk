package com.tpstreams.tpstreams_player_sdk

import android.content.Context
import com.tpstream.player.data.source.local.DownloadStatus
import com.tpstream.player.offline.TpStreamDownloadManager
import androidx.lifecycle.Observer
import com.tpstream.player.data.Asset
import io.flutter.plugin.common.BinaryMessenger

class NativeDownloadManager(
    context: Context,
    messenger: BinaryMessenger
) : NativeDownloadManagerApi, GetDownloadProgressChangeStreamStreamHandler() {
    private val downloadManager = TpStreamDownloadManager(context)
    private val downloads = downloadManager.getAllDownloads()
    private var eventSink: PigeonEventSink<DownloadProgressChangeEvent>? = null
    
    private val downloadObserver = Observer<List<Asset>?> { assets ->
        assets?.let { notifyDownloadProgress(it) }
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

    override fun onListen(p0: Any?, sink: PigeonEventSink<DownloadProgressChangeEvent>) {
        eventSink = sink
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun dispose() {
        downloads.removeObserver(downloadObserver)
        eventSink?.endOfStream()
        eventSink = null
    }

    private fun notifyDownloadProgress(assets: List<Asset>) {
        val downloadAssets = assets.map { asset ->
            mapAssetToDownloadAsset(asset)
        }
        eventSink?.success(DownloadProgressChangeEvent(downloadAssets))
    }

    private fun mapAssetToDownloadAsset(asset: Asset): DownloadAsset {
        return DownloadAsset(
            assetId = asset.id,
            title = asset.title,
            state = mapDownloadState(asset.video.downloadState),
            progress = asset.video.percentageDownloaded.toDouble()
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
