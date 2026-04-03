package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import android.content.Context
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
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
    private val playerRootView = createPlayerRootView()
    private val initializationListener = NativePlayerInitializationListener(messenger, messageChannelSuffix = id.toString())
    private val playerListener = NativePlayerListener(messenger, messageChannelSuffix = id.toString())

    private var playerView: TPStreamsPlayerView? = null
    private var player: TPStreamsPlayer? = null
    private var pendingTokenCallback: ((String) -> Unit)? = null
    private var isFullscreen = false
    private val downloadClient: DownloadClient by lazy { DownloadClient.getInstance(context) }

    private val sdkListener = object : TPStreamsPlayer.Listener {
        override fun onAccessTokenExpired(videoId: String, callback: (String) -> Unit) {
            pendingTokenCallback = callback
            playerListener.handleAccessTokenExpiration(videoId, ::handleFlutterCallResult)
        }

        override fun onError(error: PlaybackError, errorMessage: String) {
            val message = if (errorMessage.isNotEmpty()) errorMessage else error.toString()
            playerListener.onPlayerError(message, ::handleFlutterCallResult)
        }
    }

    private val playbackListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            playerListener.onPlaybackStateChanged(getPlaybackStateString(playbackState), ::handleFlutterCallResult)
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            playerRootView.keepScreenOn = isPlaying
            playerListener.onIsPlayingChanged(isPlaying, ::handleFlutterCallResult)
        }
    }

    override fun getView(): View = playerRootView

    init {
        NativePlayerApi.setUp(messenger, this, id.toString())
        setupPlayer()
    }

    private fun createPlayerRootView(): FrameLayout {
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
            notifyFlutterPlayerInitialized("Missing assetId")
            return
        }

        val existingDownload = downloadClient.getDownload(assetId)
        val hasCompletedDownload = existingDownload?.state == Download.STATE_COMPLETED

        if (isOfflinePlayback) {
            if (!hasCompletedDownload) {
                notifyFlutterPlayerInitialized(
                    "Downloaded video not found on device. Please re-download and try again."
                )
                return
            }
        } else if (accessToken.isNullOrEmpty() && !hasCompletedDownload) {
            notifyFlutterPlayerInitialized("Missing accessToken")
            return
        }

        val showDownloadOption = creationParams?.get("showDownloadOption") as? Boolean ?: false
        val startInFullscreen = creationParams?.get("startInFullscreen") as? Boolean ?: false
        val offlineLicenseExpireDays = creationParams?.get("offlineLicenseExpireDays") as? Int ?: 15
        val autoPlay = creationParams?.get("autoPlay") as? Boolean ?: true
        @Suppress("UNCHECKED_CAST")
        val metadata = creationParams?.get("metadata") as? Map<String, String> ?: emptyMap()

        @Suppress("UNCHECKED_CAST")
        val playerPrefs = creationParams?.get("playerPreferences") as? List<*>
        val enableFullscreen = playerPrefs?.let {
            TPStreamsPlayerPreferences.fromList(it).enableFullscreen
        } ?: true

        // Auto-detect: check if video is already downloaded before creating player.
        // If completed download exists, play offline (no streaming attempt).
        // Otherwise, stream online.
        val existingDownload = if (!isOfflinePlayback) {
            downloadClient.getDownload(assetId)
        } else {
            null
        }

        val isCompletedDownload = existingDownload != null &&
            existingDownload.state == Download.STATE_COMPLETED

        val effectiveIsOffline = isOfflinePlayback || isCompletedDownload

        isOfflinePlaybackRequested = effectiveIsOffline
        offlinePlaybackDownloadId = assetId
        offlinePlaybackMetadata = metadata
        isOfflineDownloadPlayback = effectiveIsOffline

        val offlineLicenseExpireSeconds = 60L * 60L * 24L * offlineLicenseExpireDays

        try {
            player = TPStreamsPlayer.create(
                context,
                assetId,
                accessToken ?: "",
                autoPlay,
                0L,
                showDownloadOption,
                false,
                startInFullscreen,
                metadata,
                offlineLicenseExpireSeconds
            )

            player?.listener = sdkListener
            player?.addListener(playbackListener)
        } catch (e: Exception) {
            Log.e("NativePlayerView", "Error creating player", e)
            val errorMessage = when (e) {
                is IllegalStateException -> "SDK not initialized. Call TPStreamsSDK.init() first."
                else -> "Failed to create player: ${e.message}"
            }
            notifyFlutterPlayerInitialized(errorMessage)
            return
        }

        playerView = TPStreamsPlayerView(context)
        playerView?.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )

        if (!enableFullscreen) {
            playerView?.post {
                playerView?.findViewById<View>(androidx.media3.ui.R.id.exo_fullscreen)
                    ?.visibility = View.GONE
            }
        }

        playerView?.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            private var wasPlayingBeforeDetach = false

            override fun onViewDetachedFromWindow(v: View) {
                wasPlayingBeforeDetach = player?.isPlaying() ?: false
            }

            override fun onViewAttachedToWindow(v: View) {
                val returningToContainer = v.parent == playerRootView
                if (returningToContainer && isFullscreen) {
                    isFullscreen = false
                    playerListener.onFullScreenChanged(false, ::handleFlutterCallResult)
                    if (wasPlayingBeforeDetach) {
                        wasPlayingBeforeDetach = false
                        v.post { player?.play() }
                    }
                } else if (!returningToContainer && !isFullscreen) {
                    isFullscreen = true
                    playerListener.onFullScreenChanged(true, ::handleFlutterCallResult)
                }
            }
        })

        playerView?.setPlayer(player)
        playerRootView.addView(playerView)

        notifyFlutterPlayerInitialized()

        if (startInFullscreen) {
            enterFullScreen()
        }
    }

    private fun notifyFlutterPlayerInitialized(initialError: String? = null) {
        initializationListener.onNativePlayerCreated(id.toLong()) { result ->
            handleFlutterCallResult(result)
            if (result.isSuccess && initialError != null) {
                playerListener.onPlayerError(initialError, ::handleFlutterCallResult)
            }
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
        metadata: Map<String, String>,
        downloadClient: DownloadClient
    ): Download? {
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
                val refreshed = injectOfflineDownloadMediaItem(downloadId, metadata, downloadClient)
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
        }
    }

    override fun exitFullScreen() {
        if (isFullscreen) {
            playerListener.beforeFullScreenExit(::handleFlutterCallResult)
            playerView?.toggleFullscreen()
        }
    }

    override fun resolveAccessToken(newAccessToken: String) {
        pendingTokenCallback?.invoke(newAccessToken)
        pendingTokenCallback = null
    }

    override fun dispose() {
        player?.removeListener(playbackListener)
        player?.release()
        playerView?.let {
            try {
                playerRootView.removeView(it)
            } catch (e: Exception) {
                Log.w("NativePlayerView", "Error removing player view during dispose", e)
            }
        }
        player = null
        playerView = null
        playerRootView.keepScreenOn = false
        pendingTokenCallback = null
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
