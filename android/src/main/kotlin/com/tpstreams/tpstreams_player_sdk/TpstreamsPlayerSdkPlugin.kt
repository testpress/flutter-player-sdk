package com.tpstreams.tpstreams_player_sdk

import android.app.Activity
import androidx.annotation.NonNull
import com.tpstream.player.TPStreamsSDK
import com.tpstream.player.TpStreamPlayer

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding


/** TpstreamsPlayerSdkPlugin */
class TpstreamsPlayerSdkPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var activity: Activity
  private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tpstreams_player_sdk")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    }else if(call.method == "initializeNativeSDK"){
      val arguments = call.arguments as? Map<String, Any>
      val orgCode = arguments?.get("orgCode") as? String
      val providerString = arguments?.get("provider") as? String

      if (orgCode != null && providerString != null) {
        val provider = if (providerString == "testpress") TPStreamsSDK.Provider.TestPress else TPStreamsSDK.Provider.TPStreams
        TPStreamsSDK.initialize(provider, orgCode)
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "tpstreams_player_sdk/player_view", PlayerViewFactory(flutterPluginBinding.binaryMessenger, activity))
  }

  override fun onDetachedFromActivityForConfigChanges() {}

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

  override fun onDetachedFromActivity() {}
}
