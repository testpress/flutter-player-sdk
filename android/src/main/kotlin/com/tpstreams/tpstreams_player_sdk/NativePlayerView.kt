package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import android.content.Context
import android.src.main.kotlin.com.tpstreams.tpstreams_player_sdk.Methods
import android.util.Log
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
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

const val FRAME_LAYOUT_ID = 0x123456

class NativePlayerView(
    val context: Context,
    messenger: BinaryMessenger,
    val id: Int,
    val creationParams: Map<String, Any>?,
    val activity: Activity
) : PlatformView, InitializationListener, MethodChannel.MethodCallHandler, TPStreamPlayerListener {
    private val linearLayout = createLinearLayout()
    private val playerFragment = TpStreamPlayerFragment()
    private var player: TpStreamPlayer? = null
    private val methodChannel: MethodChannel
    private val eventChannel: EventChannel
    private var playerEventSink: EventSink? = null

    override fun getView(): View {
        return linearLayout
    }

    init {
        val frameLayout = createFrameLayout()
        linearLayout.addView(frameLayout)
        setupPlayerFragmentOnAttach(frameLayout)
        methodChannel = MethodChannel(messenger, "tpstreams_player_sdk/player_view_$id")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(messenger, "tpstreams_player_sdk/player_view.events_$id")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, eventSink: EventSink?) {
                playerEventSink = eventSink
            }

            override fun onCancel(arguments: Any?) {
                playerEventSink = null
            }
        })

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
        val parameters = TpInitParams.Builder()
            .setVideoId(requireNotNull(assetId))
            .setAccessToken(requireNotNull(accessToken))
            .build()
        this.player!!.load(parameters)
        this.player!!.setListener(this)
        sendPlayerEvent("onNativePlayerCreated", id)
    }

    override fun dispose() {
        this.player?.release()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        this.player?.let {
            when(call.method) {
                Methods.PLAY -> executePlayerAction({ it.play() }, result)
                Methods.PAUSE -> executePlayerAction({ it.pause() }, result)
                Methods.GET_DURATION -> executePlayerAction({ it.getDuration() }, result)
                Methods.GET_CURRENT_TIME -> executePlayerAction({ it.getCurrentTime()}, result)
                Methods.DISPOSE -> executePlayerAction({ it.release() }, result)
                Methods.SEEK -> {
                    val target = call.arguments as Int
                    executePlayerAction({
                        it.seekTo(target.toLong())
                    }, result)
                }
                Methods.SET_PLAYBACK_SPEED -> {
                    val speed = call.arguments as Double
                    executePlayerAction({
                        it.setPlaybackSpeed(speed.toFloat())
                    }, result)
                }
                else -> result.notImplemented()
            }
        }?: result.error("PLAYER_ERROR", "Native Player was not initialized properly", null)
    }

    private inline fun <T> executePlayerAction(action: () -> T, result: MethodChannel.Result) {
        try {
            val actionResult = action()
            result.success(actionResult.takeIf { it != Unit })
        } catch (e: Exception) {
            result.error("PLAYER_ERROR", e.localizedMessage, null)
        }
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
        super.onPlaybackStateChanged(playbackState)
        sendPlayerEvent(Events.onPlaybackStateChanged, getPlaybackStateString(playbackState))
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
        sendPlayerEvent(Events.onIsPlayingChanged, playing)
    }

    override fun onPlayerError(playbackError: PlaybackError) {
        super.onPlayerError(playbackError)
        sendPlayerEvent(Events.onPlayerError, playbackError.toString())
    }

    private fun sendPlayerEvent(eventName: String, eventPayload: Any) {
        if (playerEventSink != null) {
            val event: MutableMap<String, Any> = HashMap()
            event["name"] = eventName
            event["payload"] = eventPayload
            playerEventSink!!.success(event)
        }
    }
}
