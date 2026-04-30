package com.tpstreams.tpstreams_player_sdk

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.fragment.app.FragmentActivity
import androidx.media3.exoplayer.offline.Download
import com.tpstreams.player.download.DownloadClient
import com.tpstreams.player.download.DownloadItem
import io.flutter.plugin.common.BinaryMessenger
import org.json.JSONObject
import org.json.JSONTokener

class NativeDownloadManager(
    context: Context,
    private val activity: FragmentActivity,
    messenger: BinaryMessenger
) : NativeDownloadManagerApi, GetDownloadsStreamStreamHandler() {
    private val downloadClient = DownloadClient.Companion.getInstance(context)
    private val migrationOrchestrator = LegacyDownloadMigrationOrchestrator()
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
        legacyDownloadStoreReader.setOnRecordsChangedListener(::notifyDownloadsChange)
        register(messenger, this)
    }

    override fun getAllDownloads(): List<DownloadAsset> {
        val currentItems = downloadClient.getAllDownloads()
        val legacyDownloadsById = legacyDownloadStoreReader.getLegacyDownloadsByAssetId()
        val legacyDownloadsByUrl = legacyDownloadStoreReader.getLegacyDownloadsByUrl()
        val matchedLegacyIds = mutableSetOf<String>()
        val matchedLegacyUrls = mutableSetOf<String>()

        val currentDownloads = currentItems.map {
            val downloadId = it.request.id
            val matchedLegacyRecord = legacyDownloadsById[downloadId] ?: legacyDownloadsByUrl[downloadId]
            if (matchedLegacyRecord != null) {
                matchedLegacyIds += matchedLegacyRecord.assetId
                if (matchedLegacyRecord.url.isNotBlank()) {
                    matchedLegacyUrls += matchedLegacyRecord.url
                }
            }

            mapDownloadToDownloadAsset(it, matchedLegacyRecord)
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
                DownloadAsset(
                    assetId = legacyRecord.effectiveDownloadId,
                    title = legacyRecord.title,
                    state = legacyRecord.state,
                    progress = legacyRecord.progress,
                    metadata = legacyRecord.metadata
                )
            }

        return currentDownloads + legacyDownloads
    }

    override fun startDownload(assetId: String, accessToken: String?, metadata: Map<String, String>?, resolution: String?) {
        downloadClient.startDownload(activity, assetId, accessToken ?: "", resolution, metadata)
        notifyDownloadsChange()
    }

    override fun cancelDownload(asset: DownloadAsset) {
        removeDownloadAndCleanup(asset)
    }

    override fun resumeDownload(asset: DownloadAsset) {
        downloadClient.resumeDownload(asset.assetId)
        notifyDownloadsChange()
    }

    override fun deleteDownload(asset: DownloadAsset) {
        removeDownloadAndCleanup(asset)
    }

    override fun pauseDownload(asset: DownloadAsset) {
        downloadClient.pauseDownload(asset.assetId)
        notifyDownloadsChange()
    }

    override fun deleteAllDownloads() {
        downloadClient.getAllDownloads().forEach { item ->
            downloadClient.removeDownload(item.request.id)
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
        eventSink = null
        stopListening()
    }

    override fun dispose() {
        stopListening()
        legacyDownloadStoreReader.setOnRecordsChangedListener(null)
        legacyDownloadStoreReader.dispose()
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

    private fun mapDownloadToDownloadAsset(
        item: Download,
        legacyRecord: LegacyDownloadRecord?
    ): DownloadAsset {
        val computedProgress = if (item.contentLength > 0L) {
            ((item.bytesDownloaded.toDouble() / item.contentLength.toDouble()) * 100.0).coerceIn(0.0, 100.0)
        } else {
            item.percentDownloaded.toDouble().coerceIn(0.0, 100.0)
        }

        val requestJsonObject = parseRequestJsonObject(item)
        val parsedMetadata = parseRequestMetadata(requestJsonObject)
        val metadataWithMigrationState = parsedMetadata.toMutableMap()
        var title = parseRequestTitle(requestJsonObject)

        if (legacyRecord != null) {
            metadataWithMigrationState.putAll(legacyRecord.metadata)
            if (migrationOrchestrator.isLegacyCandidate(title, metadataWithMigrationState)) {
                title = legacyRecord.title
            }
        }

        return DownloadAsset(
            assetId = item.request.id,
            title = title,
            state = mapDownloadState(item.state),
            progress = computedProgress,
            metadata = metadataWithMigrationState
        )
    }

    private fun parseRequestJsonObject(download: Download): JSONObject? {
        val requestData = download.request.data ?: return null
        return try {
            val parsed = JSONTokener(String(requestData, Charsets.UTF_8)).nextValue()
            parsed as? JSONObject
        } catch (_: Exception) {
            null
        }
    }

    private fun parseRequestTitle(requestJsonObject: JSONObject?): String {
        return requestJsonObject?.optString("title", "Unknown Title") ?: "Unknown Title"
    }

    private fun parseRequestMetadata(requestJsonObject: JSONObject?): Map<String, String> {
        val metadataObject = requestJsonObject?.optJSONObject("metadata")
            ?: requestJsonObject?.optJSONObject("customMetadata")
            ?: requestJsonObject?.optJSONObject("custom_metadata")
            ?: return emptyMap()

        return metadataObject.keys().asSequence().associateWith { key ->
            metadataObject.optString(key, "")
        }
    }

    private fun removeDownloadAndCleanup(asset: DownloadAsset) {
        downloadClient.removeDownload(asset.assetId)
        cleanupLegacyRecordIfPresent(asset)
        notifyDownloadsChange()
    }

    private fun cleanupLegacyRecordIfPresent(asset: DownloadAsset) {
        asset.metadata?.get(LegacyDownloadMigrationOrchestrator.LEGACY_VIDEO_ID_KEY)?.let {
            legacyDownloadStoreReader.deleteLegacyDownload(it)
        }
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
