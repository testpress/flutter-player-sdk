package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import android.content.Context
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.offline.Download
import com.tpstreams.player.download.DownloadClient
import com.tpstreams.player.TPStreamsPlayer
import com.tpstreams.player.TPStreamsPlayerView
import com.tpstreams.player.constants.PlaybackError
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView

class NativePlayerView(
    val context: Context,
    messenger: BinaryMessenger,
    val id: Int,
    val creationParams: Map<String, Any>?,
    val activity: Activity
) : PlatformView, NativePlayerApi {
    private val container = createContainer()
    private val initializationListener = NativePlayerInitializationListener(messenger, messageChannelSuffix = id.toString())
    private val playerListener = NativePlayerListener(messenger, messageChannelSuffix = id.toString())

    private var playerView: TPStreamsPlayerView? = null
    private var player: TPStreamsPlayer? = null
    private var pendingTokenCallback: ((String) -> Unit)? = null
    private var isFullscreen = false
    private var isOfflinePlaybackRequested = false
    private var isOfflineDownloadPlayback = false
    private var offlinePlaybackDownloadId: String? = null
    private var offlinePlaybackMetadata: Map<String, String> = emptyMap()
    private var isOfflineReinjectInProgress = false

    private val sdkListener = object : TPStreamsPlayer.Listener {
        override fun onAccessTokenExpired(videoId: String, callback: (String) -> Unit) {
            pendingTokenCallback = callback
            playerListener.handleAccessTokenExpiration(videoId, ::handleFlutterCallResult)
        }

        override fun onError(error: PlaybackError, errorMessage: String) {
            if (shouldSuppressOfflineFallbackError(errorMessage)) {
                Log.d("NativePlayerView", "Ignoring transient online fallback error during offline playback: $errorMessage")
                return
            }
            val message = if (errorMessage.isNotEmpty()) errorMessage else error.toString()
            playerListener.onPlayerError(message, ::handleFlutterCallResult)
        }
    }

    private val playbackListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            playerListener.onPlaybackStateChanged(getPlaybackStateString(playbackState), ::handleFlutterCallResult)
        }

        override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
            val sdkPlayer = player ?: return
            val downloadId = offlinePlaybackDownloadId
            if (!isOfflinePlaybackRequested || !playWhenReady || downloadId.isNullOrBlank()) {
                return
            }

            if (sdkPlayer.isPlaying() || isOfflineReinjectInProgress) {
                return
            }

            isOfflineReinjectInProgress = true
            try {
                val refreshed = injectOfflineDownloadMediaItem(downloadId, offlinePlaybackMetadata)
                if (refreshed) {
                    isOfflineDownloadPlayback = true
                }
            } finally {
                isOfflineReinjectInProgress = false
            }
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            container.keepScreenOn = isPlaying
            playerListener.onIsPlayingChanged(isPlaying, ::handleFlutterCallResult)
        }
    }

    override fun getView(): View = container

    init {
        setupPlayer()
        NativePlayerApi.setUp(messenger, this, id.toString())
    }

    private fun createContainer(): FrameLayout {
        return FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
    }

    private fun setupPlayer() {
        val assetId = creationParams?.get("assetId") as? String
        val accessToken = creationParams?.get("accessToken") as? String
        val isOfflinePlayback = creationParams?.get("isOfflinePlayback") as? Boolean ?: false

        if (assetId.isNullOrEmpty()) {
            playerListener.onPlayerError("Missing assetId", ::handleFlutterCallResult)
            return
        }

        if (!isOfflinePlayback && accessToken.isNullOrEmpty()) {
            playerListener.onPlayerError("Missing accessToken", ::handleFlutterCallResult)
            return
        }

        val showDownloadOption = creationParams?.get("showDownloadOption") as? Boolean ?: false
        val startInFullscreen = creationParams?.get("startInFullscreen") as? Boolean ?: false
        val offlineLicenseExpireDays = creationParams?.get("offlineLicenseExpireDays") as? Int ?: 15
        val autoPlay = creationParams?.get("autoPlay") as? Boolean ?: true
        @Suppress("UNCHECKED_CAST")
        val metadata = creationParams?.get("metadata") as? Map<String, String> ?: emptyMap()

        isOfflinePlaybackRequested = isOfflinePlayback
        offlinePlaybackDownloadId = assetId
        offlinePlaybackMetadata = metadata
        isOfflineDownloadPlayback = false

        // Read player preferences (encoded as ordered List by Pigeon)
        @Suppress("UNCHECKED_CAST")
        val playerPrefs = creationParams?.get("playerPreferences") as? List<*>
        val enableFullscreen = playerPrefs?.getOrNull(0) as? Boolean ?: true

        val offlineLicenseExpireSeconds = 60L * 60L * 24L * offlineLicenseExpireDays
        val effectiveAutoPlay = if (isOfflinePlayback) false else autoPlay

        // SDK signature (1.1.10 source):
        // create(context, assetId, accessToken, shouldAutoPlay, startAt,
        //        enableDownload, showDefaultCaptions, startInFullscreen,
        //        downloadMetadata, offlineLicenseExpireTime)
        player = TPStreamsPlayer.Companion.create(
            context,
            assetId,
            accessToken ?: "",
            effectiveAutoPlay,
            0L,
            showDownloadOption,
            false,
            startInFullscreen,
            metadata,
            offlineLicenseExpireSeconds
        )

        player?.listener = sdkListener
        player?.addListener(playbackListener)

        playerView = TPStreamsPlayerView(context)
        playerView?.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )

        // Hide the native fullscreen button when the preference disables it.
        if (!enableFullscreen) {
            playerView?.post {
                playerView?.findViewById<View>(androidx.media3.ui.R.id.exo_fullscreen)
                    ?.visibility = View.GONE
            }
        }

        // Attach listener to:
        // 1. Sync isFullscreen when the user uses the native fullscreen button.
        // 2. Resume playback after the view returns to the embedded container, working
        //    around the SDK's synchronous play-state check that fires before the surface
        //    is ready after a fullscreen exit.
        playerView?.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            private var wasPlayingBeforeDetach = false

            override fun onViewDetachedFromWindow(v: View) {
                wasPlayingBeforeDetach = player?.isPlaying() ?: false
            }

            override fun onViewAttachedToWindow(v: View) {
                val returningToContainer = v.parent == container
                if (returningToContainer && isFullscreen) {
                    // View returned to the embedded container → fullscreen exited.
                    isFullscreen = false
                    playerListener.onFullScreenChanged(false, ::handleFlutterCallResult)
                    if (wasPlayingBeforeDetach) {
                        wasPlayingBeforeDetach = false
                        // post() ensures the surface is ready before we ask the player to play.
                        v.post { player?.play() }
                    }
                } else if (!returningToContainer && !isFullscreen) {
                    // View moved to decor view via native button → fullscreen entered.
                    isFullscreen = true
                    playerListener.onFullScreenChanged(true, ::handleFlutterCallResult)
                }
            }
        })

        playerView?.setPlayer(player)
        container.addView(playerView)

        if (isOfflinePlayback) {
            // TPStreamsPlayerView wraps the player's listener in setPlayer() and shows a
            // native error overlay on every onError callback. For offline flow we suppress
            // transient online fallback errors, so restore our listener after binding.
            player?.listener = sdkListener
        }

        if (isOfflinePlayback) {
            // Force offline media item injection for all offline playback entries
            // to avoid SDK failures when parsing DRM license URI from download request data.
            isOfflineDownloadPlayback = injectOfflineDownloadMediaItem(assetId, metadata)
            if (isOfflineDownloadPlayback && autoPlay) {
                player?.play()
            } else if (!isOfflineDownloadPlayback) {
                playerListener.onPlayerError("Downloaded video not found on device. Please re-download and try again.", ::handleFlutterCallResult)
            }
        }

        initializationListener.onNativePlayerCreated(id.toLong(), ::handleFlutterCallResult)

        if (startInFullscreen) {
            enterFullScreen()
        }
    }

    private fun injectOfflineDownloadMediaItem(
        downloadId: String,
        metadata: Map<String, String>
    ): Boolean {
        val download = findOfflineDownload(downloadId, metadata)
        if (download == null) {
            Log.w("NativePlayerView", "No download found for offline playback id: $downloadId")
            return false
        }

        val mediaItem = buildOfflineDownloadMediaItem(download)
        if (mediaItem == null) {
            Log.w("NativePlayerView", "Failed to build offline media item for: $downloadId")
            return false
        }

        player?.refreshPlaybackWithDownloadMediaItem(mediaItem)
        markOfflinePlayerPrepared()
        return true
    }

    private fun markOfflinePlayerPrepared() {
        val sdkPlayer = player ?: return
        try {
            val isPreparedField = sdkPlayer.javaClass.getDeclaredField("isPrepared")
            isPreparedField.isAccessible = true
            isPreparedField.setBoolean(sdkPlayer, true)
        } catch (exception: Exception) {
            Log.w("NativePlayerView", "Failed to mark offline player prepared", exception)
        }
    }

    private fun findOfflineDownload(
        downloadId: String,
        metadata: Map<String, String>
    ): Download? {
        val downloadClient = DownloadClient.getInstance(context)
        return downloadClient.getDownload(downloadId)
    }

    private fun buildOfflineDownloadMediaItem(download: Download): MediaItem? {
        return try {
            val request = download.request
            val builder = MediaItem.Builder()
                .setMediaId(request.id)
                .setUri(request.uri)
                .setCustomCacheKey(request.customCacheKey)
                .setMimeType(request.mimeType)
                .setStreamKeys(request.streamKeys)

            request.keySetId?.let { keySetId ->
                val drmConfig = MediaItem.DrmConfiguration.Builder(C.WIDEVINE_UUID)
                    .setKeySetId(keySetId)
                    .setMultiSession(false)
                    .build()
                builder.setDrmConfiguration(drmConfig)
            }

            builder.build()
        } catch (exception: Exception) {
            Log.e("NativePlayerView", "Error building offline media item", exception)
            null
        }
    }

    private fun shouldSuppressOfflineFallbackError(errorMessage: String): Boolean {
        if (!isOfflinePlaybackRequested) return false

        val normalizedMessage = errorMessage.lowercase()
        if (normalizedMessage.contains("error code: 5001")) return true

        val looksLikeOnlineAuthError = normalizedMessage.contains("don't have permission") ||
            normalizedMessage.contains("do not have permission") ||
            normalizedMessage.contains("check your credential") ||
            normalizedMessage.contains("unauthorized") ||
            normalizedMessage.contains("forbidden")

        return looksLikeOnlineAuthError
    }

    override fun play() {
        val sdkPlayer = player ?: throw IllegalStateException("Player not initialized")

        if (isOfflinePlaybackRequested) {
            val downloadId = creationParams?.get("assetId") as? String
            @Suppress("UNCHECKED_CAST")
            val metadata = creationParams?.get("metadata") as? Map<String, String> ?: emptyMap()

            if (!downloadId.isNullOrBlank()) {
                val refreshed = injectOfflineDownloadMediaItem(downloadId, metadata)
                if (refreshed) {
                    return
                }
            }
        }

        sdkPlayer.play()
    }

    override fun pause() {
        player?.pause() ?: throw IllegalStateException("Player not initialized")
    }

    override fun seek(position: Long) {
        player?.seekTo(position) ?: throw IllegalStateException("Player not initialized")
    }

    override fun setPlaybackSpeed(speed: Double) {
        player?.setPlaybackSpeed(speed.toFloat()) ?: throw IllegalStateException("Player not initialized")
    }

    override fun setMaxResolution(resolution: Long) {
        player?.setVideoResolution(resolution.toInt()) ?: throw IllegalStateException("Player not initialized")
    }

    override fun getDuration(): Long {
        return player?.duration ?: throw IllegalStateException("Player not initialized")
    }

    override fun getCurrentTime(): Long {
        return player?.currentPosition ?: throw IllegalStateException("Player not initialized")
    }

    override fun enterFullScreen() {
        if (!isFullscreen) {
            playerListener.beforeFullScreenEnter(::handleFlutterCallResult)
            playerView?.toggleFullscreen()
            // isFullscreen and onFullScreenChanged are handled by the attach listener
            // (which fires synchronously during toggleFullscreen's view reparenting).
        }
    }

    override fun exitFullScreen() {
        if (isFullscreen) {
            playerListener.beforeFullScreenExit(::handleFlutterCallResult)
            playerView?.toggleFullscreen()
            // isFullscreen, onFullScreenChanged, and playback resume are handled by the
            // attach listener (which fires synchronously during toggleFullscreen).
        }
    }

    override fun resolveAccessToken(newAccessToken: String) {
        pendingTokenCallback?.invoke(newAccessToken)
        pendingTokenCallback = null
    }

    override fun dispose() {
        player?.removeListener(playbackListener)
        player?.release()
        player = null
        playerView = null
        container.keepScreenOn = false
    }

    private fun getPlaybackStateString(playbackState: Int): String {
        return when (playbackState) {
            Player.STATE_IDLE -> "idle"
            Player.STATE_BUFFERING -> "buffering"
            Player.STATE_READY -> "ready"
            Player.STATE_ENDED -> {
                playerListener.notifyReplay(::handleFlutterCallResult)
                "ended"
            }
            else -> "unknown"
        }
    }

    private fun handleFlutterCallResult(result: Result<Unit>) {
        if (result.isFailure) {
            Log.e("NativePlayerView", "Failed to call flutter from native: ${result.exceptionOrNull()?.message}")
        }
    }
}
