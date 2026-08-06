package com.example.jjibudung_v2

import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "jjibudung/posture_service"
        const val STREAM_CHANNEL = "jjibudung/posture_stream"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STREAM_CHANNEL
        ).setStreamHandler(PostureStreamHandler(this))

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "ping" -> result.success("pong")

                "start" -> {
                    val baselineAngle = call.argument<Double>("baselineAngle") ?: 0.0
                    val angleThreshold = call.argument<Double>("angleThreshold") ?: 15.0

                    val serviceIntent = Intent(this, PostureService::class.java).apply {
                        putExtra(PostureService.EXTRA_BASELINE_ANGLE, baselineAngle)
                        putExtra(PostureService.EXTRA_ANGLE_THRESHOLD, angleThreshold)
                    }

                    ContextCompat.startForegroundService(this, serviceIntent)
                    result.success(true)
                }

                "stop" -> {
                    stopService(Intent(this, PostureService::class.java))
                    result.success(true)
                }

                "getCurrentAngle" -> result.success(PostureService.currentAngle)
                "getBaseline" -> result.success(PostureService.baselineAngle)
                "isBadPosture" -> result.success(PostureService.isBadPosture())
                "getState" -> result.success(
                    if (PostureService.isRunning) "running" else "stopped"
                )

                // Flutter 화면이 닫혀 있어도 서비스가 누적한 실제 세션 값이다.
                "getSessionData" -> result.success(PostureService.getSessionData())

                "updateBaseline" -> {
                    val baselineAngle = call.argument<Double>("baselineAngle")
                    if (baselineAngle == null) {
                        result.error("INVALID_ARGUMENT", "baselineAngle is required", null)
                    } else {
                        PostureService.baselineAngle = baselineAngle
                        result.success(true)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
