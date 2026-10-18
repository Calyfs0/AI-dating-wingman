package com.wingman.wingman

import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gotchu/sfx",
        ).setMethodCallHandler { call, result ->
            if (call.method == "keyClick") {
                val am = getSystemService(AUDIO_SERVICE) as AudioManager
                am.playSoundEffect(AudioManager.FX_KEYPRESS_STANDARD, 1.0f)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
