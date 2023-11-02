package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import android.content.Context
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

const val FRAME_LAYOUT_ID = 0x123456

class NativePlayerView(
    val context: Context,
    messenger: BinaryMessenger,
    id: Int,
    val creationParams: Map<String, Any>?,
    val activity: Activity
) : PlatformView, InitializationListener {
    private val linearLayout = createLinearLayout()
    private val playerFragment = TpStreamPlayerFragment()
    private lateinit var player: TpStreamPlayer

    override fun getView(): View {
        return linearLayout
    }

    init {
        val frameLayout = createFrameLayout()
        linearLayout.addView(frameLayout)
        setupPlayerFragmentOnAttach(frameLayout)
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
        this.player.load(parameters)
    }

    override fun dispose() {}
}
