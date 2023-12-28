package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import android.content.Context
import android.src.main.kotlin.com.tpstreams.tpstreams_player_sdk.Methods
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.fragment.app.FragmentActivity
import com.tpstream.player.TpInitParams
import com.tpstream.player.TpStreamPlayer
import com.tpstream.player.ui.InitializationListener
import com.tpstream.player.ui.TpStreamPlayerFragment
import io.flutter.plugin.common.BinaryMessenger
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
) : PlatformView, InitializationListener, MethodChannel.MethodCallHandler {
    private val linearLayout = createLinearLayout()
    private val playerFragment = TpStreamPlayerFragment()
    private var player: TpStreamPlayer? = null
    private val methodChannel: MethodChannel

    override fun getView(): View {
        return linearLayout
    }

    init {
        val frameLayout = createFrameLayout()
        linearLayout.addView(frameLayout)
        setupPlayerFragmentOnAttach(frameLayout)
        methodChannel = MethodChannel(messenger, "tpstreams_player_sdk/player_view_$id")
        methodChannel.setMethodCallHandler(this)
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
        methodChannel.invokeMethod("onNativePlayerCreated", id);
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
}
