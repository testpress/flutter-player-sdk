package com.tpstreams.tpstreams_player_sdk

class LegacyDownloadMigrationOrchestrator {

    fun isLegacyCandidate(title: String, metadata: Map<String, String>): Boolean {
        val hasLegacyPointer = metadata.containsKey(LEGACY_VIDEO_ID_KEY) ||
            metadata.containsKey(LEGACY_URL_KEY)
        if (hasLegacyPointer) {
            return true
        }

        // New SDK falls back to this title when metadata JSON parsing fails.
        // Old sdk entries encoded title bytes directly in DownloadRequest.data.
        // Require empty metadata as an extra guard to reduce false positives.
        return title == LEGACY_UNKNOWN_TITLE && metadata.isEmpty()
    }

    companion object {
        const val LEGACY_VIDEO_ID_KEY = "tpstreams_legacy_video_id"
        const val LEGACY_URL_KEY = "tpstreams_legacy_url"

        private const val LEGACY_UNKNOWN_TITLE = "Unknown Title"
    }
}
