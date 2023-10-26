package com.tpstreams.tpstreams_player_sdk

import android.content.Context
import android.view.View
import android.widget.TextView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView


class NativePlayerView internal constructor(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Map<String, Any>?

) : PlatformView {
    private val textView: TextView

    override fun getView(): View {
        return textView
    }

    init {
        textView = TextView(context)
        textView.text = creationParams?.get("assetId") as String
    }

    override fun dispose(){}
}
