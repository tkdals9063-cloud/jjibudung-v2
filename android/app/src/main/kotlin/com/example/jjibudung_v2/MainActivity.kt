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
            STREAM_CHANNEL,
        ).setStreamHandler(PostureStreamHandler(this))

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "ping" -> result.success("pong")

                "start" -> {
                    val baselinePitch =
                        call.argument<Double>("baselinePitch") ?: 0.0
                    val baselineRoll =
                        call.argument<Double>("baselineRoll") ?: 0.0
                    val pitchThreshold =
                        call.argument<Double>("pitchThreshold") ?: 15.0
                    val rollThreshold =
                        call.argument<Double>("rollThreshold") ?: 10.0

                    val serviceIntent =
                        Intent(this, PostureService::class.java).apply {
                            putExtra(
                                PostureService.EXTRA_BASELINE_PITCH,
                                baselinePitch,
                            )
                            putExtra(
                                PostureService.EXTRA_BASELINE_ROLL,
                                baselineRoll,
                            )
                            putExtra(
                                PostureService.EXTRA_PITCH_THRESHOLD,
                                pitchThreshold,
                            )
                            putExtra(
                                PostureService.EXTRA_ROLL_THRESHOLD,
                                rollThreshold,
                            )
                        }

                    ContextCompat.startForegroundService(this, serviceIntent)
                    result.success(true)
                }

                "stop" -> {
                    stopService(Intent(this, PostureService::class.java))
                    result.success(true)
                }

                "getCurrentAngle" -> result.success(PostureService.currentPitch)
                "getCurrentRoll" -> result.success(PostureService.currentRoll)
                "getBaseline" -> result.success(PostureService.baselinePitch)
                "getBaselineRoll" -> result.success(PostureService.baselineRoll)
                "isBadPosture" -> result.success(PostureService.isBadPosture())

                "getState" -> result.success(
                    if (PostureService.isRunning) "running" else "stopped",
                )

                "getSessionData" -> {
                    result.success(PostureService.getSessionData())
                }

                "updateBaseline" -> {
                    val baselinePitch =
                        call.argument<Double>("baselinePitch")
                    val baselineRoll =
                        call.argument<Double>("baselineRoll")

                    if (baselinePitch == null || baselineRoll == null) {
                        result.error(
                            "INVALID_ARGUMENT",
                            "baselinePitch and baselineRoll are required",
                            null,
                        )
                    } else {
                        PostureService.baselinePitch = baselinePitch
                        PostureService.baselineRoll = baselineRoll
                        result.success(true)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}