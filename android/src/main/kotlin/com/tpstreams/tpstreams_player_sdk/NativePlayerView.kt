package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.fragment.app.FragmentActivity
import com.tpstream.player.TPStreamPlayerListener
import com.tpstream.player.TpInitParams
import com.tpstream.player.TpStreamPlayer
import com.tpstream.player.constants.PlaybackError
import com.tpstream.player.ui.InitializationListener
import com.tpstream.player.ui.TpStreamPlayerFragment
import com.tpstream.player.TpStreamPlayerPreference
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView
import android.util.Log

const val FRAME_LAYOUT_ID = 0x123456

class NativePlayerView(
    val context: Context,
    messenger: BinaryMessenger,
    val id: Int,
    val creationParams: Map<String, Any>?,
    val activity: Activity
) : PlatformView, InitializationListener, TPStreamPlayerListener, NativePlayerApi {
    private val linearLayout = createLinearLayout()
    private val playerFragment = TpStreamPlayerFragment()
    private var player: TpStreamPlayer? = null
    
    private val initializationListener = NativePlayerInitializationListener(messenger, messageChannelSuffix = id.toString())
    private val playerListener = NativePlayerListener(messenger, messageChannelSuffix = id.toString())
    private var pendingTokenCallback: ((String) -> Unit)? = null

    override fun getView(): View {
        return linearLayout
    }

    init {
        val frameLayout = createFrameLayout()
        linearLayout.addView(frameLayout)
        setupPlayerFragmentOnAttach(frameLayout)

        NativePlayerApi.setUp(messenger, this, id.toString())
    }

    private fun createLinearLayout(): LinearLayout {
        val vParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        val layout = LinearLayout(context)
        layout.orientation = LinearLayout.VERTICAL
        layout.layoutParams = vParams
        return layout
    }

    private fun createFrameLayout(): FrameLayout {
        val layout = FrameLayout(context)
        layout.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        layout.id = FRAME_LAYOUT_ID
        return layout
    }

    private fun setupPlayerFragmentOnAttach(frameLayout: FrameLayout) {
        frameLayout.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                initializePlayerFragment()
            }

            override fun onViewDetachedFromWindow(v: View) {}
        })
    }

    private fun initializePlayerFragment() {
        if (activity is FragmentActivity) {
            playerFragment.setOnInitializationListener(this)
            val fragmentManager = activity.supportFragmentManager
            val fragmentTransaction = fragmentManager.beginTransaction()
            fragmentTransaction.replace(
                FRAME_LAYOUT_ID,
                playerFragment,
                playerFragment::class.toString()
            )
            fragmentTransaction.commitNow()
        }
    }

    override fun onInitializationSuccess(player: TpStreamPlayer) {
        this.player = player
        val assetId = creationParams?.get("assetId") as? String
        val accessToken = creationParams?.get("accessToken") as? String
        val showDownloadOption = creationParams?.get("showDownloadOption") as? Boolean ?: false
        val startInFullscreen = creationParams?.get("startInFullscreen") as? Boolean ?: false
        val offlineLicenseExpireDays = creationParams?.get("offlineLicenseExpireDays") as? Int ?: 15
        val isOfflinePlayback = creationParams?.get("isOfflinePlayback") as? Boolean ?: false
        val metadata = creationParams?.get("metadata") as? Map<String, String>

        val playerPreferences = creationParams?.get("playerPreferences")

        val parameters = getTpInitParams(assetId, accessToken, showDownloadOption, offlineLicenseExpireDays, isOfflinePlayback, playerPreferences)
        
        this.player!!.load(parameters, metadata)
        this.player!!.setListener(this)
        
        if (startInFullscreen) {
            playerFragment.showFullScreen()
        }

        initializationListener.onNativePlayerCreated(id.toLong(), handleFlutterCallResult)
    }

    private fun getTpInitParams(
        assetId: String?, 
        accessToken: String?,
        showDownloadOption: Boolean,
        offlineLicenseExpireDays: Int,
        isOfflinePlayback: Boolean,
        playerPreferences: Any?
    ): TpInitParams {
        return if (isOfflinePlayback) {
            TpInitParams.createOfflineParams(requireNotNull(assetId))
        } else {
            TpInitParams.Builder()
                .setVideoId(requireNotNull(assetId))
                .setAccessToken(requireNotNull(accessToken))
                .apply {
                    if (showDownloadOption) {
                        enableDownloadSupport(true)
                        setOfflineLicenseExpireTime(60 * 60 * 24 * offlineLicenseExpireDays)
                    }
                    playerPreferences?.let { prefsList ->
                        val prefs = TPStreamsPlayerPreferences.fromList(prefsList as List<Any?>)
                        val preferenceBuilder = TpStreamPlayerPreference.Builder()
                        preferenceBuilder.enableFullscreen(prefs.enableFullscreen)
                        preferenceBuilder.enablePlaybackSpeed(prefs.enablePlaybackSpeed)
                        preferenceBuilder.enableCaptions(prefs.enableCaptions)
                        preferenceBuilder.showResolutionOptions(prefs.showResolutionOptions)
                        preferenceBuilder.enableSeekButtons(prefs.enableSeekButtons)
                        prefs.seekBarColor?.let { preferenceBuilder.setSeekBarColor(it.toInt()) }
                        setPlayerPreference(preferenceBuilder.build())
                    }
                }
                .build()
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

    override fun getDuration(): Long {
        return player?.getDuration() ?: throw IllegalStateException("Player not initialized")
    }

    override fun getCurrentTime(): Long {
        return player?.getCurrentTime() ?: throw IllegalStateException("Player not initialized")
    }

    override fun dispose() {
        player?.release()
        player = null
        linearLayout.keepScreenOn = false
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
        super.onPlaybackStateChanged(playbackState)
        playerListener.onPlaybackStateChanged(getPlaybackStateString(playbackState), handleFlutterCallResult)
        linearLayout.keepScreenOn = playbackState == TpStreamPlayer.PLAYBACK_STATE.STATE_BUFFERING
    }

    private fun getPlaybackStateString(playbackState: Int): String {
        return when (playbackState) {
            TpStreamPlayer.PLAYBACK_STATE.STATE_IDLE -> "idle"
            TpStreamPlayer.PLAYBACK_STATE.STATE_BUFFERING -> "buffering"
            TpStreamPlayer.PLAYBACK_STATE.STATE_READY -> "ready"
            TpStreamPlayer.PLAYBACK_STATE.STATE_ENDED -> "ended"
            else -> "unknown"
        }
    }

    override fun onIsPlayingChanged(playing: Boolean) {
        super.onIsPlayingChanged(playing)
        linearLayout.keepScreenOn = playing
        playerListener.onIsPlayingChanged(playing, handleFlutterCallResult)
    }

    override fun onPlayerError(playbackError: PlaybackError) {
        super.onPlayerError(playbackError)
        playerListener.onPlayerError(playbackError.toString(), handleFlutterCallResult)
    }

    override fun onFullScreenChanged(fullScreen: Boolean) {
        super.onFullScreenChanged(fullScreen)
        playerListener.onFullScreenChanged(fullScreen, handleFlutterCallResult)
    }

    override fun onBeforeFullScreenEnter() {
        super.onBeforeFullScreenEnter()
        playerListener.beforeFullScreenEnter(handleFlutterCallResult)
    }

    override fun onBeforeFullScreenExit() {
        super.onBeforeFullScreenExit()
        playerListener.beforeFullScreenExit(handleFlutterCallResult)
    }

    override fun onAccessTokenExpired(videoId: String, callback: (String) -> Unit) {
        pendingTokenCallback = callback
        playerListener.handleAccessTokenExpiration(videoId, handleFlutterCallResult)
    }

    override fun resolveAccessToken(newAccessToken: String) {
        pendingTokenCallback?.invoke(newAccessToken)
        pendingTokenCallback = null
    }

    private val handleFlutterCallResult: (Result<Unit>) -> Unit = { result ->
        if (result.isFailure) {
            Log.e("NativePlayerView", "Failed to call flutter from native: ${result.exceptionOrNull()?.message}")
        }
    }
}
