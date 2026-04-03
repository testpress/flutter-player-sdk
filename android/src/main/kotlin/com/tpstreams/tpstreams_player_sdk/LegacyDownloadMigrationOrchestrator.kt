package com.tpstreams.tpstreams_player_sdk

import android.content.Context
import com.tpstreams.player.download.DownloadItem

/**
 * Phase-1 migration helper:
 * - detects legacy candidates non-destructively,
 * - records detection stats for observability,
 * - exposes a stable legacy marker used in mapped metadata.
 */
class LegacyDownloadMigrationOrchestrator(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

    fun recordLegacyCandidates(items: List<DownloadItem>) {
        val legacyCount = items.count(::isLegacyCandidate)
        preferences.edit()
            .putInt(KEY_LEGACY_CANDIDATE_COUNT, legacyCount)
            .putLong(KEY_LAST_SCAN_EPOCH_MS, System.currentTimeMillis())
            .apply()
    }

    fun isLegacyCandidate(item: DownloadItem): Boolean {
        // New SDK falls back to this title when metadata JSON parsing fails.
        // Old sdk entries encoded title bytes directly in DownloadRequest.data.
        return item.title == LEGACY_UNKNOWN_TITLE
    }

    companion object {
        const val MIGRATION_STATE_KEY = "tpstreams_migration_state"
        const val MIGRATION_STATE_LEGACY_DETECTED = "legacy_detected"
        const val MIGRATION_STATE_METADATA_HYDRATED = "metadata_hydrated"
        const val MIGRATION_SOURCE_KEY = "tpstreams_migration_source"
        const val MIGRATION_SOURCE_LEGACY_ROOM = "legacy_room"
        const val MIGRATION_SOURCE_LEGACY_ROOM_BRIDGED = "legacy_room_bridged"
        const val MIGRATION_SOURCE_NEW_DOWNLOAD_CLIENT = "new_download_client"
        const val MIGRATION_SOURCE_LEGACY_ROOM_HYDRATED = "legacy_room_hydrated"
        const val LEGACY_VIDEO_ID_KEY = "tpstreams_legacy_video_id"
        const val LEGACY_URL_KEY = "tpstreams_legacy_url"

        private const val PREFERENCES_NAME = "tpstreams_download_migration"
        private const val KEY_LEGACY_CANDIDATE_COUNT = "legacy_candidate_count"
        private const val KEY_LAST_SCAN_EPOCH_MS = "last_scan_epoch_ms"

        private const val LEGACY_UNKNOWN_TITLE = "Unknown Title"
    }
}
