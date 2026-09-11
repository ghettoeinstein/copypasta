package com.calebpierre.copypasta

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the Flutter clip store to the SharedPreferences file the
 * CopyPastaInputMethodService reads, so the keyboard extension sees new
 * clips without any Flutter engine of its own.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.calebpierre.copypasta/clip_bridge"
    private val prefsName = "copypasta_shared"
    private val clipsKey = "clips_json"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncClips" -> {
                    val json = call.argument<String>("json") ?: "[]"
                    getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                        .edit()
                        .putString(clipsKey, json)
                        .apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
