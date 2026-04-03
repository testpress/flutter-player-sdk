package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import androidx.annotation.NonNull
import androidx.fragment.app.FragmentActivity
import com.tpstreams.player.TPStreamsSDK

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding


/** TpstreamsPlayerSdkPlugin */
class TpstreamsPlayerSdkPlugin: FlutterPlugin, ActivityAware, NativeSDKApi {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var activity: Activity
  private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
  private var downloadManager: NativeDownloadManager? = null
  private var isPlayerViewFactoryRegistered = false

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding
    NativeSDKApi.setUp(flutterPluginBinding.binaryMessenger, this)
  }

  override fun initialize(provider: PROVIDER, orgCode: String) {
    TPStreamsSDK.init(orgCode)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    tearDownDownloadManager()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    attachToActivity(binding.activity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    tearDownDownloadManager()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    attachToActivity(binding.activity)
  }

  override fun onDetachedFromActivity() {
    tearDownDownloadManager()
  }

  private fun attachToActivity(activity: Activity) {
    this.activity = activity

    if (!isPlayerViewFactoryRegistered) {
      flutterPluginBinding.platformViewRegistry.registerViewFactory(
        "tpstreams_player_sdk/player_view",
        PlayerViewFactory(flutterPluginBinding.binaryMessenger, activity)
      )
      isPlayerViewFactoryRegistered = true
    }

    if (activity !is FragmentActivity) {
      NativeDownloadManagerApi.setUp(flutterPluginBinding.binaryMessenger, null)
      return
    }

    downloadManager?.dispose()
    downloadManager = NativeDownloadManager(
      flutterPluginBinding.applicationContext,
      activity,
      flutterPluginBinding.binaryMessenger
    )
    NativeDownloadManagerApi.setUp(flutterPluginBinding.binaryMessenger, downloadManager)
  }

  private fun tearDownDownloadManager() {
    downloadManager?.dispose()
    downloadManager = null
    NativeDownloadManagerApi.setUp(flutterPluginBinding.binaryMessenger, null)
  }
}
