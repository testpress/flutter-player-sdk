package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import android.content.Context
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView
import com.tpstream.player.TpInitParams
import com.tpstream.player.TpStreamPlayer
import com.tpstream.player.ui.TPStreamPlayerView


class NativePlayerView internal constructor(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Map<String, Any>?,
    activity: Activity

) : PlatformView {
    private val playerView = TPStreamPlayerView(activity)
    private val tpStreamsPlayer = TpStreamPlayer.Builder(activity).build()

    override fun getView(): View {
        return playerView
    }

    init {
        val parameters = TpInitParams.Builder()
            .setVideoId(creationParams?.get("assetId") as String)
            .setAccessToken(creationParams.get("accessToken") as String)
            .build()
        tpStreamsPlayer.load(parameters)
        playerView.setPlayer(tpStreamsPlayer)
    }

    override fun dispose(){}
}
