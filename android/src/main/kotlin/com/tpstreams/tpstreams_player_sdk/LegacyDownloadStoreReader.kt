package com.tpstreams.tpstreams_player_sdk

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import org.json.JSONObject

data class LegacyDownloadRecord(
    val assetId: String,
    val url: String,
    val title: String,
    val state: DownloadState,
    val progress: Double,
    val metadata: Map<String, String>
) {
    val effectiveDownloadId: String
        get() = if (url.isNotBlank()) url else assetId
}

class LegacyDownloadStoreReader(private val context: Context) {
    @Volatile
    private var cachedRecords: List<LegacyDownloadRecord>? = null

    fun getLegacyDownloadsByAssetId(): Map<String, LegacyDownloadRecord> {
        return getCachedLegacyDownloads().associateBy { it.assetId }
    }

    fun getLegacyDownloadsByUrl(): Map<String, LegacyDownloadRecord> {
        return getCachedLegacyDownloads()
            .filter { it.url.isNotBlank() }
            .associateBy { it.url }
    }

    fun deleteLegacyDownload(videoId: String) {
        val databasePath = context.getDatabasePath(LEGACY_DATABASE_NAME)
        if (!databasePath.exists()) {
            return
        }

        val database = SQLiteDatabase.openDatabase(
            databasePath.path,
            null,
            SQLiteDatabase.OPEN_READWRITE
        )

        database.use { db ->
            db.delete(LEGACY_ASSET_TABLE, "videoId = ?", arrayOf(videoId))
        }

        invalidateCache()
    }

    fun deleteAllLegacyDownloads() {
        val databasePath = context.getDatabasePath(LEGACY_DATABASE_NAME)
        if (!databasePath.exists()) {
            return
        }

        val database = SQLiteDatabase.openDatabase(
            databasePath.path,
            null,
            SQLiteDatabase.OPEN_READWRITE
        )

        database.use { db ->
            db.delete(LEGACY_ASSET_TABLE, null, null)
        }

        invalidateCache()
    }

    private fun getCachedLegacyDownloads(): List<LegacyDownloadRecord> {
        val existing = cachedRecords
        if (existing != null) {
            return existing
        }

        val loaded = loadFromDatabase()
        cachedRecords = loaded
        return loaded
    }

    private fun invalidateCache() {
        cachedRecords = null
    }

    private fun loadFromDatabase(): List<LegacyDownloadRecord> {
        val databasePath = context.getDatabasePath(LEGACY_DATABASE_NAME)
        if (!databasePath.exists()) {
            return emptyList()
        }

        val database = SQLiteDatabase.openDatabase(
            databasePath.path,
            null,
            SQLiteDatabase.OPEN_READONLY
        )

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
                        metadata[LegacyDownloadMigrationOrchestrator.MIGRATION_STATE_KEY] =
                            LegacyDownloadMigrationOrchestrator.MIGRATION_STATE_LEGACY_DETECTED
                        metadata[LegacyDownloadMigrationOrchestrator.MIGRATION_SOURCE_KEY] =
                            LegacyDownloadMigrationOrchestrator.MIGRATION_SOURCE_LEGACY_ROOM
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

    private fun mapLegacyState(rawState: String?): DownloadState {
        return when (rawState?.uppercase()) {
            "DOWNLOADING" -> DownloadState.DOWNLOADING
            "PAUSE" -> DownloadState.PAUSED
            "COMPLETE" -> DownloadState.COMPLETED
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
        private const val LEGACY_DATABASE_NAME = "tpStreams-database"
        private const val LEGACY_ASSET_TABLE = "Asset"
    }
}
