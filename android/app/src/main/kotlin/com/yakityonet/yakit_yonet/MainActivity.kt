package com.yakityonet.yakit_yonet

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yakityonet/trip_intent"
    private var methodChannel: MethodChannel? = null
    private var pendingIntentData: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialIntentData" -> {
                    result.success(getIntentData(intent))
                }
                "getPendingIntentData" -> {
                    result.success(pendingIntentData)
                    pendingIntentData = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val data = getIntentData(intent)
        if (data != null) {
            pendingIntentData = data
            methodChannel?.invokeMethod("onNewIntentData", data)
        }
    }

    private fun getIntentData(intent: Intent?): String? {
        intent ?: return null
        return when {
            intent.action == Intent.ACTION_SEND && intent.type == "text/plain" ->
                intent.getStringExtra(Intent.EXTRA_TEXT)
            intent.action == Intent.ACTION_VIEW && intent.data?.scheme == "geo" ->
                intent.data?.toString()
            else -> null
        }
    }
}
