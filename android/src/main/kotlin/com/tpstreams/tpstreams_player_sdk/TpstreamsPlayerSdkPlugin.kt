package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import androidx.annotation.NonNull
import com.tpstream.player.TPStreamsSDK
import com.tpstream.player.TpStreamPlayer

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import com.tpstreams.tpstreams_player_sdk.NativeSDKApi


/** TpstreamsPlayerSdkPlugin */
class TpstreamsPlayerSdkPlugin: FlutterPlugin, ActivityAware, NativeSDKApi {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var activity: Activity
  private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
  private var downloadManagerApi: TPStreamsDownloadManagerApi? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding
    NativeSDKApi.setUp(flutterPluginBinding.binaryMessenger, this)
  }

  override fun initialize(provider: PROVIDER, orgCode: String) {
    val sdkProvider = when (provider) {
      PROVIDER.TESTPRESS -> TPStreamsSDK.Provider.TestPress
      PROVIDER.TPSTREAMS -> TPStreamsSDK.Provider.TPStreams
    }
    TPStreamsSDK.initialize(sdkProvider, orgCode)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    downloadManagerApi?.dispose()
    downloadManagerApi = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "tpstreams_player_sdk/player_view", PlayerViewFactory(flutterPluginBinding.binaryMessenger, activity))

    this.downloadManagerApi = TPStreamsDownloadManagerApi(
      flutterPluginBinding.applicationContext,
      flutterPluginBinding.binaryMessenger
    )
    NativeDownloadManagerApi.setUp(flutterPluginBinding.binaryMessenger, this.downloadManagerApi!!)
  }

  override fun onDetachedFromActivityForConfigChanges() {}

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

  override fun onDetachedFromActivity() {}
}
