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
import com.tpstreams.player.WatermarkAnimation as NativeWatermarkAnimation
import com.tpstreams.player.WatermarkAnimationType as NativeWatermarkAnimationType
import com.tpstreams.player.WatermarkConfig as NativeWatermarkConfig
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
    private var isDisposed = false
    private val downloadClient: DownloadClient by lazy { DownloadClient.getInstance(context) }
    private val legacyDownloadStoreReader: LegacyDownloadStoreReader by lazy {
        LegacyDownloadStoreReader(context)
    }

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
        val requestedAssetId = creationParams?.get("assetId") as? String
        val accessToken = creationParams?.get("accessToken") as? String
        val isOfflinePlayback = creationParams?.get("isOfflinePlayback") as? Boolean ?: false

        if (requestedAssetId.isNullOrEmpty()) {
            notifyFlutterPlayerInitialized("Missing assetId")
            return
        }

        legacyDownloadStoreReader.getLegacyDownloadByAssetIdAsync(requestedAssetId) { legacyRecord ->
            if (isDisposed || player != null) {
                return@getLegacyDownloadByAssetIdAsync
            }
            setupPlayerWithResolvedLegacyRecord(
                requestedAssetId = requestedAssetId,
                accessToken = accessToken,
                isOfflinePlayback = isOfflinePlayback,
                legacyRecord = legacyRecord
            )
        }
    }

    private fun setupPlayerWithResolvedLegacyRecord(
        requestedAssetId: String,
        accessToken: String?,
        isOfflinePlayback: Boolean,
        legacyRecord: LegacyDownloadRecord?
    ) {
        val playbackAssetId = resolvePlaybackAssetId(requestedAssetId, legacyRecord)
        val existingDownload = downloadClient.getDownload(playbackAssetId)
        val hasCompletedDownload = (existingDownload?.state == Download.STATE_COMPLETED) ||
            (legacyRecord?.state == DownloadState.COMPLETED && legacyRecord.effectiveDownloadId == playbackAssetId)
        val shouldPreferOfflinePlayback = isOfflinePlayback || hasCompletedDownload

        if (isOfflinePlayback) {
            if (!hasCompletedDownload) {
                notifyFlutterPlayerInitialized(
                    "Downloaded video not found on device. Please re-download and try again."
                )
                return
            }
        } else if (accessToken.isNullOrEmpty() && !hasCompletedDownload) {
            // For Testpress, accessToken is optional if authToken was provided during initialization.
            // We'll pass an empty string and let the SDK handle it.
            Log.d("NativePlayerView", "AccessToken is empty, relying on global authToken if available")
        }

        val showDownloadOption = creationParams?.get("showDownloadOption") as? Boolean ?: false
        val startInFullscreen = creationParams?.get("startInFullscreen") as? Boolean ?: false
        val offlineLicenseExpireDays = creationParams?.get("offlineLicenseExpireDays") as? Int ?: 15
        val autoPlay = creationParams?.get("autoPlay") as? Boolean ?: true
        @Suppress("UNCHECKED_CAST")
        val metadata = creationParams?.get("metadata") as? Map<String, String> ?: emptyMap()
        val playbackAccessToken = if (shouldPreferOfflinePlayback) "" else (accessToken ?: "")

        @Suppress("UNCHECKED_CAST")
        val playerPrefs = creationParams?.get("playerPreferences") as? List<*>
        val enableFullscreen = playerPrefs?.let {
            TPStreamsPlayerPreferences.fromList(it).enableFullscreen
        } ?: true

        val offlineLicenseExpireSeconds = 60L * 60L * 24L * offlineLicenseExpireDays

        try {
            player = TPStreamsPlayer.create(
                context,
                playbackAssetId,
                playbackAccessToken,
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

        val themedContext = android.view.ContextThemeWrapper(activity, androidx.appcompat.R.style.Theme_AppCompat_NoActionBar)
        playerView = TPStreamsPlayerView(themedContext)
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

        val resolution = creationParams?.get("resolution") as? Int
        if (resolution != null) {
            playerView?.setVideoResolution(resolution)
        }

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
    }

    override fun play() {
        player?.play() ?: throw IllegalStateException("Player not initialized")
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
        val res = resolution.toInt()
        player?.setMaxResolution(res) ?: throw IllegalStateException("Player not initialized")
        playerView?.setVideoResolution(res)
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

    override fun enableAutoFullscreenOnRotate() {
        playerView?.setAutoFullscreenOnRotateEnabled(true)
    }

    override fun disableAutoFullscreenOnRotate() {
        playerView?.setAutoFullscreenOnRotateEnabled(false)
    }

    override fun setWatermarks(configs: List<WatermarkConfig>) {
        val view = playerView ?: throw IllegalStateException("Player not initialized")
        val nativeConfigs = configs.map {
            NativeWatermarkConfig(
                text = it.text,
                x = it.x.toInt(),
                y = it.y.toInt(),
                color = it.color.toInt(),
                textSize = it.textSize.toFloat(),
                opacity = it.opacity.toFloat(),
                animation = it.animation?.let { anim ->
                    NativeWatermarkAnimation(
                        type = mapAnimationType(anim.type),
                        duration = anim.duration,
                    )
                },
            )
        }
        view.setWatermarks(nativeConfigs)
    }

    override fun clearWatermarks() {
        playerView?.clearWatermarks() ?: throw IllegalStateException("Player not initialized")
    }

    private fun mapAnimationType(type: WatermarkAnimationType): NativeWatermarkAnimationType = when (type) {
        WatermarkAnimationType.PING_PONG -> NativeWatermarkAnimationType.PING_PONG
    }

    override fun resolveAccessToken(newAccessToken: String) {
        pendingTokenCallback?.invoke(newAccessToken)
        pendingTokenCallback = null
    }

    override fun dispose() {
        isDisposed = true
        player?.removeListener(playbackListener)
        player?.release()
        legacyDownloadStoreReader.dispose()
        playerView?.clearWatermarks()
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

    private fun resolvePlaybackAssetId(
        requestedAssetId: String,
        legacyRecord: LegacyDownloadRecord?
    ): String {
        if (downloadClient.getDownload(requestedAssetId) != null) {
            return requestedAssetId
        }

        val record = legacyRecord ?: return requestedAssetId

        val effectiveDownloadId = record.effectiveDownloadId
        if (effectiveDownloadId.isBlank()) {
            return requestedAssetId
        }

        return if (downloadClient.getDownload(effectiveDownloadId) != null) {
            effectiveDownloadId
        } else if (record.state == DownloadState.COMPLETED) {
            effectiveDownloadId
        } else {
            requestedAssetId
        }
    }
}
