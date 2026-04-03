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
    private val migrationOrchestrator = LegacyDownloadMigrationOrchestrator(context)
    private val legacyDownloadStoreReader = LegacyDownloadStoreReader(context)
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
        val legacyDownloadsById = legacyDownloadStoreReader.getLegacyDownloadsByAssetId()
        val legacyDownloadsByUrl = legacyDownloadStoreReader.getLegacyDownloadsByUrl()
        val matchedLegacyIds = mutableSetOf<String>()
        val matchedLegacyUrls = mutableSetOf<String>()

        val currentDownloads = downloadClient.getAllDownloadItems().map {
            val matchedLegacyRecord = legacyDownloadsById[it.assetId] ?: legacyDownloadsByUrl[it.assetId]
            if (matchedLegacyRecord != null) {
                matchedLegacyIds += matchedLegacyRecord.assetId
                if (matchedLegacyRecord.url.isNotBlank()) {
                    matchedLegacyUrls += matchedLegacyRecord.url
                }
            }

            mapDownloadItemToDownloadAsset(it, matchedLegacyRecord)
        }
        val currentDownloadIds = currentDownloads.map { it.assetId }.toHashSet()

        val legacyDownloads = legacyDownloadsById.values
            .filterNot { legacyRecord ->
                legacyRecord.assetId in currentDownloadIds ||
                    legacyRecord.assetId in matchedLegacyIds ||
                    (legacyRecord.url.isNotBlank() && legacyRecord.url in currentDownloadIds) ||
                    (legacyRecord.url.isNotBlank() && legacyRecord.url in matchedLegacyUrls)
            }
            .map { legacyRecord ->
                val metadata = legacyRecord.metadata.toMutableMap()
                val canBridgeToCurrentDownloadIndex = legacyRecord.url.isNotBlank()
                metadata[LegacyDownloadMigrationOrchestrator.MIGRATION_STATE_KEY] =
                    if (canBridgeToCurrentDownloadIndex) {
                        LegacyDownloadMigrationOrchestrator.MIGRATION_STATE_METADATA_HYDRATED
                    } else {
                        LegacyDownloadMigrationOrchestrator.MIGRATION_STATE_LEGACY_DETECTED
                    }
                metadata[LegacyDownloadMigrationOrchestrator.MIGRATION_SOURCE_KEY] =
                    if (canBridgeToCurrentDownloadIndex) {
                        LegacyDownloadMigrationOrchestrator.MIGRATION_SOURCE_LEGACY_ROOM_BRIDGED
                    } else {
                        LegacyDownloadMigrationOrchestrator.MIGRATION_SOURCE_LEGACY_ROOM
                    }

                DownloadAsset(
                    assetId = legacyRecord.effectiveDownloadId,
                    title = legacyRecord.title,
                    state = legacyRecord.state,
                    progress = legacyRecord.progress,
                    metadata = metadata
                )
            }

        return currentDownloads + legacyDownloads
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
        asset.metadata?.get(LegacyDownloadMigrationOrchestrator.LEGACY_VIDEO_ID_KEY)?.let {
            legacyDownloadStoreReader.deleteLegacyDownload(it)
        }
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
        legacyDownloadStoreReader.deleteAllLegacyDownloads()
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
<<<<<<< HEAD
=======
        stopPolling()
>>>>>>> bd8855b (Upgrade to TPStreams Android SDK 1.1.10)
        eventSink = null
        stopListening()
    }

    override fun dispose() {
<<<<<<< HEAD
        stopListening()
=======
        stopPolling()
        downloadClient.removeListener(listener)
>>>>>>> bd8855b (Upgrade to TPStreams Android SDK 1.1.10)
        eventSink?.endOfStream()
        eventSink = null
    }

<<<<<<< HEAD
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
=======
    private fun startPolling() {
        if (isPolling) {
            return
        }
        isPolling = true
        mainHandler.post(pollRunnable)
    }

    private fun stopPolling() {
        if (!isPolling) {
            return
        }
        isPolling = false
        mainHandler.removeCallbacks(pollRunnable)
    }

    private fun notifyDownloadsChange() {
        eventSink?.success(DownloadsUpdateEvent(getAllDownloads()))
>>>>>>> bd8855b (Upgrade to TPStreams Android SDK 1.1.10)
    }

    private fun mapDownloadItemToDownloadAsset(
        item: DownloadItem,
        legacyRecord: LegacyDownloadRecord?
    ): DownloadAsset {
<<<<<<< HEAD
<<<<<<< HEAD
        val computedProgress = if (item.totalBytes > 0L) {
            ((item.downloadedBytes.toDouble() / item.totalBytes.toDouble()) * 100.0).coerceIn(0.0, 100.0)
        } else {
            item.progressPercentage.toDouble().coerceIn(0.0, 100.0)
        }

=======
>>>>>>> bd8855b (Upgrade to TPStreams Android SDK 1.1.10)
=======
        val metadataWithMigrationState = item.metadata?.toMutableMap() ?: mutableMapOf()
        var title = item.title

        if (migrationOrchestrator.isLegacyCandidate(item) && legacyRecord != null) {
            metadataWithMigrationState.putAll(legacyRecord.metadata)
            metadataWithMigrationState[LegacyDownloadMigrationOrchestrator.MIGRATION_STATE_KEY] =
                LegacyDownloadMigrationOrchestrator.MIGRATION_STATE_METADATA_HYDRATED
            metadataWithMigrationState[LegacyDownloadMigrationOrchestrator.MIGRATION_SOURCE_KEY] =
                LegacyDownloadMigrationOrchestrator.MIGRATION_SOURCE_LEGACY_ROOM_HYDRATED
            title = legacyRecord.title
        } else {
            metadataWithMigrationState[LegacyDownloadMigrationOrchestrator.MIGRATION_SOURCE_KEY] =
                LegacyDownloadMigrationOrchestrator.MIGRATION_SOURCE_NEW_DOWNLOAD_CLIENT
        }

        if (migrationOrchestrator.isLegacyCandidate(item) && legacyRecord == null) {
            metadataWithMigrationState[LegacyDownloadMigrationOrchestrator.MIGRATION_STATE_KEY] =
                LegacyDownloadMigrationOrchestrator.MIGRATION_STATE_LEGACY_DETECTED
        }

>>>>>>> 4649a69 (feat: Add legacy download migration for Android)
        return DownloadAsset(
            assetId = item.assetId,
            title = title,
            state = mapDownloadState(item.state),
<<<<<<< HEAD
            progress = computedProgress,
=======
            progress = item.progressPercentage.toDouble(),
<<<<<<< HEAD
>>>>>>> bd8855b (Upgrade to TPStreams Android SDK 1.1.10)
            metadata = item.metadata ?: emptyMap()
=======
            metadata = metadataWithMigrationState
>>>>>>> 4649a69 (feat: Add legacy download migration for Android)
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
