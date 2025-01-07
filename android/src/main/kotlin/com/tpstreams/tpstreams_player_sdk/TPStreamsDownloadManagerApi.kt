package com.tpstreams.tpstreams_player_sdk

import android.content.Context
import com.tpstream.player.data.source.local.DownloadStatus
import com.tpstream.player.offline.TpStreamDownloadManager
import androidx.lifecycle.Observer
import com.tpstream.player.data.Asset
import io.flutter.plugin.common.BinaryMessenger

class TPStreamsDownloadManagerApi(
    context: Context,
    messenger: BinaryMessenger
) : NativeDownloadManagerApi, GetDownloadProgressChangeStreamStreamHandler() {
    private val downloadManager = TpStreamDownloadManager(context)
    private val downloads = downloadManager.getAllDownloads()
    private var eventSink: PigeonEventSink<DownloadProgressChangeEvent>? = null
    private val downloadObserver = Observer<List<Asset>?> { assets ->
        notifyDownloadProgress(assets)
    }

    init {
        downloads.observeForever(downloadObserver)

        register(messenger, this)
    }

    private fun notifyDownloadProgress(assets: List<Asset>?) {
        val downloadAssets = assets?.map { asset ->
            DownloadAsset(
                assetId = asset.id,
                title = asset.title,
                state = mapDownloadState(asset.video.downloadState),
                progress = asset.video.percentageDownloaded.toDouble()
            )
        } ?: emptyList()
        eventSink?.success(DownloadProgressChangeEvent(downloadAssets))
    }

    private fun mapDownloadState(nativeState: DownloadStatus?): DownloadState {
        return when (nativeState) {
            DownloadStatus.DOWNLOADING -> DownloadState.DOWNLOADING
            DownloadStatus.PAUSE -> DownloadState.PAUSED
            DownloadStatus.COMPLETE -> DownloadState.COMPLETED
            DownloadStatus.FAILED -> DownloadState.FAILED
            else -> DownloadState.NOT_DOWNLOADED
        }
    }

    override fun getAllDownloads(): List<DownloadAsset> {
        return downloads.value?.map { asset ->
            DownloadAsset(
                assetId = asset.id,
                title = asset.title,
                state = mapDownloadState(asset.video.downloadState),
                progress = asset.video.percentageDownloaded.toDouble()
            )
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
}
