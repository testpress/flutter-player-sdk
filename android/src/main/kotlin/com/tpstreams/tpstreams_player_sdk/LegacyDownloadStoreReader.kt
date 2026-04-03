package com.tpstreams.tpstreams_player_sdk

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.util.Log
import org.json.JSONObject
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

data class LegacyDownloadRecord(
    val assetId: String,
    val url: String,
    val title: String,
    val state: DownloadState,
    val progress: Double,
    val metadata: Map<String, String>
) {
    // Legacy rows may only have a persisted URL key; we expose that as the effective
    // identifier so delete/bridge logic can still match the old download entry.
    val effectiveDownloadId: String
        get() = if (url.isLikelyDownloadIdUrl()) url else assetId
}

class LegacyDownloadStoreReader(private val context: Context) {
    private val lock = Any()
    private val ioExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    @Volatile private var cachedRecords: List<LegacyDownloadRecord> = emptyList()
    @Volatile private var isCacheLoaded = false
    @Volatile private var onRecordsChanged: (() -> Unit)? = null

    init {
        refreshCacheAsync(notify = false)
    }

    fun setOnRecordsChangedListener(listener: (() -> Unit)?) {
        onRecordsChanged = listener
    }

    fun getLegacyDownloadsByAssetId(): Map<String, LegacyDownloadRecord> {
        return getCachedLegacyDownloads().associateBy { it.assetId }
    }

    fun getLegacyDownloadsByUrl(): Map<String, LegacyDownloadRecord> {
        return getCachedLegacyDownloads()
            .filter { it.url.isNotBlank() }
            .associateBy { it.url }
    }

    fun dispose() {
        onRecordsChanged = null
        ioExecutor.shutdown()
    }

    fun deleteLegacyDownload(videoId: String) {
        val databasePath = context.getDatabasePath(LEGACY_DATABASE_NAME)
        if (!databasePath.exists()) {
            return
        }

        ioExecutor.execute {
            val database = try {
                SQLiteDatabase.openDatabase(
                    databasePath.path,
                    null,
                    SQLiteDatabase.OPEN_READWRITE
                )
            } catch (exception: Exception) {
                Log.e(TAG, "Failed to open legacy DB for deletion", exception)
                dispatchRecordsChanged()
                return@execute
            }

            database.use { db ->
                db.delete(LEGACY_ASSET_TABLE, "videoId = ?", arrayOf(videoId))
            }

            refreshCacheAsync(notify = true)
        }
    }

    fun deleteAllLegacyDownloads() {
        val databasePath = context.getDatabasePath(LEGACY_DATABASE_NAME)
        if (!databasePath.exists()) {
            return
        }

        ioExecutor.execute {
            val database = try {
                SQLiteDatabase.openDatabase(
                    databasePath.path,
                    null,
                    SQLiteDatabase.OPEN_READWRITE
                )
            } catch (exception: Exception) {
                Log.e(TAG, "Failed to open legacy DB for delete-all", exception)
                dispatchRecordsChanged()
                return@execute
            }

            database.use { db ->
                db.delete(LEGACY_ASSET_TABLE, null, null)
            }

            refreshCacheAsync(notify = true)
        }
    }

    private fun getCachedLegacyDownloads(): List<LegacyDownloadRecord> {
        ensureCacheWarmup()
        synchronized(lock) {
            return cachedRecords
        }
    }

    private fun ensureCacheWarmup() {
        if (!isCacheLoaded) {
            refreshCacheAsync(notify = true)
        }
    }

    private fun refreshCacheAsync(notify: Boolean) {
        ioExecutor.execute {
            val loaded = loadFromDatabase()
            synchronized(lock) {
                cachedRecords = loaded
                isCacheLoaded = true
            }
            if (notify) {
                dispatchRecordsChanged()
            }
        }
    }

    private fun loadFromDatabase(): List<LegacyDownloadRecord> {
        val databasePath = context.getDatabasePath(LEGACY_DATABASE_NAME)
        if (!databasePath.exists()) {
            return emptyList()
        }

        val database = try {
            SQLiteDatabase.openDatabase(
                databasePath.path,
                null,
                SQLiteDatabase.OPEN_READONLY
            )
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to open legacy DB for read", exception)
            return emptyList()
        }

        return database.use { db ->
            val cursor = db.query(
                LEGACY_ASSET_TABLE,
                arrayOf("videoId", "url", "title", "percentageDownloaded", "downloadState", "metadata"),
                "downloadState IS NOT NULL",
                null,
                null,
                null,
                null
            )

            cursor.use {
                val assetIdIdx = cursor.getColumnIndexOrThrow("videoId")
                val urlIdx = cursor.getColumnIndexOrThrow("url")
                val titleIdx = cursor.getColumnIndexOrThrow("title")
                val progressIdx = cursor.getColumnIndexOrThrow("percentageDownloaded")
                val stateIdx = cursor.getColumnIndexOrThrow("downloadState")
                val metadataIdx = cursor.getColumnIndexOrThrow("metadata")

                buildList {
                    while (cursor.moveToNext()) {
                        val assetId = cursor.getString(assetIdIdx) ?: continue
                        val url = cursor.getString(urlIdx) ?: ""
                        val title = cursor.getString(titleIdx) ?: "Untitled"
                        val progress = cursor.getDouble(progressIdx)
                        val state = mapLegacyState(cursor.getString(stateIdx))
                        val metadata = parseMetadata(cursor.getString(metadataIdx)).toMutableMap()
                        metadata[LegacyDownloadMigrationOrchestrator.LEGACY_VIDEO_ID_KEY] = assetId
                        if (url.isNotBlank()) {
                            metadata[LegacyDownloadMigrationOrchestrator.LEGACY_URL_KEY] = url
                        }

                        add(
                            LegacyDownloadRecord(
                                assetId = assetId,
                                url = url,
                                title = title,
                                state = state,
                                progress = progress,
                                metadata = metadata
                            )
                        )
                    }
                }
            }
        }
    }

    private fun dispatchRecordsChanged() {
        onRecordsChanged?.invoke()
    }

    private fun mapLegacyState(rawState: String?): DownloadState {
        return when (rawState?.uppercase()) {
            "DOWNLOADING", "QUEUED", "RESTARTING" -> DownloadState.DOWNLOADING
            "PAUSE", "PAUSED", "STOPPED" -> DownloadState.PAUSED
            "COMPLETE", "COMPLETED" -> DownloadState.COMPLETED
            "FAILED" -> DownloadState.FAILED
            else -> DownloadState.NOT_DOWNLOADED
        }
    }

    private fun parseMetadata(rawMetadata: String?): Map<String, String> {
        if (rawMetadata.isNullOrBlank()) {
            return emptyMap()
        }

        return try {
            val jsonObject = JSONObject(rawMetadata)
            jsonObject.keys().asSequence().associateWith { key ->
                jsonObject.optString(key, "")
            }
        } catch (_: Exception) {
            emptyMap()
        }
    }

    companion object {
        private const val TAG = "LegacyDownloadStore"
        private const val LEGACY_DATABASE_NAME = "tpStreams-database"
        private const val LEGACY_ASSET_TABLE = "Asset"
    }
}

private fun String.isLikelyDownloadIdUrl(): Boolean {
    if (isBlank()) return false
    return try {
        val parsed = Uri.parse(this)
        !parsed.scheme.isNullOrBlank()
    } catch (_: Exception) {
        false
    }
}
