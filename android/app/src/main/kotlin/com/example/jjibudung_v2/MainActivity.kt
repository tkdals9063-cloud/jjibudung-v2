package com.example.jjibudung_v2

import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "jjibudung/posture_service"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "ping" -> {
                    result.success("pong")
                }

                "start" -> {
                    ContextCompat.startForegroundService(
                        this,
                        Intent(this, PostureService::class.java)
                    )
                    result.success(true)
                }

                "stop" -> {
                    stopService(Intent(this, PostureService::class.java))
                    result.success(true)
                }

                "getCurrentAngle" -> {
                    result.success(PostureService.currentAngle)
                }

                else -> result.notImplemented()
            }

        }
    }
}