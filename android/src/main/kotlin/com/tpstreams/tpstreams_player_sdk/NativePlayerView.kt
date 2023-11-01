package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import android.content.Context
import android.util.Log
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
import io.flutter.plugin.platform.PlatformView


class NativePlayerView internal constructor(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    val creationParams: Map<String, Any>?,
    val activity: Activity

) : PlatformView, InitializationListener {
    private var linearLayout: LinearLayout
    private lateinit var player: TpStreamPlayer
    private lateinit var playerFragment: TpStreamPlayerFragment
    var FRAME_LAYOUT_ID = 0x123456

    override fun getView(): View {
        return linearLayout
    }

    init {
        linearLayout = LinearLayout(context)
        linearLayout.isClickable = false
        val vParams: ViewGroup.LayoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        )
        val frameLayout = FrameLayout(context)
        frameLayout.layoutParams = vParams
        frameLayout.id = FRAME_LAYOUT_ID
        frameLayout.isClickable = false
        linearLayout.addView(frameLayout)

        frameLayout.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                initializePlayerFragment()
            }

            override fun onViewDetachedFromWindow(v: View) {}
        })
    }

    private fun initializePlayerFragment() {
        if (activity is FragmentActivity) {
            playerFragment = TpStreamPlayerFragment()
            playerFragment.setOnInitializationListener(this)
            val fm = activity.supportFragmentManager
            fm.beginTransaction().replace(
                FRAME_LAYOUT_ID,
                playerFragment,
                playerFragment::class.toString()
            ).commitNow()
        }
    }

    override fun onInitializationSuccess(player: TpStreamPlayer) {
        this.player = player
        val parameters = TpInitParams.Builder()
            .setVideoId(creationParams?.get("assetId") as String)
            .setAccessToken(creationParams.get("accessToken") as String)
            .build()
        this.player.load(parameters)
    }

    override fun dispose(){}
}
