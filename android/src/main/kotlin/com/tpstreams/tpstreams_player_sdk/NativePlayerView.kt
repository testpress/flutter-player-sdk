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


class NativePlayerView(
    val context: Context,
    messenger: BinaryMessenger,
    id: Int,
    val creationParams: Map<String, Any>?,
    val activity: Activity
) : PlatformView, InitializationListener {

    private val linearLayout = LinearLayout(context)
    private val playerFragment = TpStreamPlayerFragment()
    private lateinit var player: TpStreamPlayer

    companion object {
        const val FRAME_LAYOUT_ID = 0x123456
    }

    override fun getView(): View {
        return linearLayout
    }

    init {
        initializeLinearLayout()
        addFrameLayout()
        setAttachStateChangeListener()
    }

    private fun initializeLinearLayout() {
        val vParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        linearLayout.orientation = LinearLayout.VERTICAL
        linearLayout.layoutParams = vParams
    }

    private fun addFrameLayout() {
        val frameLayout = FrameLayout(context)
        frameLayout.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        frameLayout.id = FRAME_LAYOUT_ID
        linearLayout.addView(frameLayout)
    }

    private fun setAttachStateChangeListener() {
        val frameLayout = linearLayout.findViewById<FrameLayout>(FRAME_LAYOUT_ID)
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
        val assetId = creationParams?.get("assetId") as? String
        val accessToken = creationParams?.get("accessToken") as? String
        val parameters = TpInitParams.Builder()
            .setVideoId(assetId!!)
            .setAccessToken(accessToken!!)
            .build()
        this.player.load(parameters)
    }

    override fun dispose() {}
}
