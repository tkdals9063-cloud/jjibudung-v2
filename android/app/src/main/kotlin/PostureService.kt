package com.example.jjibudung_v2

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import kotlin.math.abs
import kotlin.math.max

class PostureService : Service(), SensorEventListener {

    companion object {
        const val CHANNEL_ID = "posture_service_channel"
        const val NOTIFICATION_ID = 1001
        const val EXTRA_BASELINE_ANGLE = "baselineAngle"
        const val EXTRA_ANGLE_THRESHOLD = "angleThreshold"

        // 나쁜 자세가 끊기지 않고 이 시간(30분)을 넘기면 한 번 진동한다.
        const val VIBRATION_THRESHOLD_MILLIS = 30 * 60 * 1000L

        @Volatile var currentAngle = 0.0
        @Volatile var baselineAngle = 0.0
        @Volatile var angleThreshold = 15.0
        @Volatile var isRunning = false

        @Volatile private var sessionStartElapsedMillis = 0L
        @Volatile private var badPostureMillis = 0L
        @Volatile private var lastAccountingMillis = 0L
        @Volatile private var continuousBadPostureMillis = 0L
        @Volatile private var hasVibratedForCurrentStreak = false

        fun isBadPosture(): Boolean {
            return abs(currentAngle - baselineAngle) > angleThreshold
        }

        fun getSessionData(): Map<String, Any> {
            if (sessionStartElapsedMillis == 0L) {
                return mapOf(
                    "totalSeconds" to 0,
                    "badSeconds" to 0,
                    "goodSeconds" to 0,
                    "postureRate" to 100.0,
                    "currentAngle" to currentAngle,
                    "baselineAngle" to baselineAngle,
                    "isBadPosture" to false,
                    "isRunning" to false,
                )
            }

            accountElapsed(SystemClock.elapsedRealtime())

            val totalSeconds = ((SystemClock.elapsedRealtime() - sessionStartElapsedMillis) / 1000)
                .toInt()
                .coerceAtLeast(0)
            val badSeconds = (badPostureMillis / 1000)
                .toInt()
                .coerceIn(0, totalSeconds)
            val goodSeconds = max(0, totalSeconds - badSeconds)
            val postureRate = if (totalSeconds == 0) 100.0
            else goodSeconds.toDouble() / totalSeconds * 100.0

            return mapOf(
                "totalSeconds" to totalSeconds,
                "badSeconds" to badSeconds,
                "goodSeconds" to goodSeconds,
                "postureRate" to postureRate,
                "currentAngle" to currentAngle,
                "baselineAngle" to baselineAngle,
                "isBadPosture" to isBadPosture(),
                "isRunning" to isRunning,
            )
        }

        private fun accountElapsed(now: Long) {
            if (!isRunning || lastAccountingMillis == 0L) return

            val elapsed = now - lastAccountingMillis
            if (elapsed > 0) {
                if (isBadPosture()) {
                    badPostureMillis += elapsed
                    continuousBadPostureMillis += elapsed
                } else {
                    continuousBadPostureMillis = 0L
                    hasVibratedForCurrentStreak = false
                }
            }
            lastAccountingMillis = now
        }

        // 연속 나쁜 자세가 기준치를 막 넘긴 순간에만 true를 반환한다(한 스트릭당 한 번).
        fun consumeVibrationTrigger(): Boolean {
            if (hasVibratedForCurrentStreak) return false
            if (continuousBadPostureMillis < VIBRATION_THRESHOLD_MILLIS) return false

            hasVibratedForCurrentStreak = true
            return true
        }
    }

    private lateinit var sensorManager: SensorManager
    private var rotationSensor: Sensor? = null
    private val rotationMatrix = FloatArray(9)
    private val orientation = FloatArray(3)
    private val handler = Handler(Looper.getMainLooper())

    private val accountingTicker = object : Runnable {
        override fun run() {
            accountElapsed(SystemClock.elapsedRealtime())
            if (consumeVibrationTrigger()) {
                vibrate()
            }
            handler.postDelayed(this, 1000)
        }
    }

    private fun isVibrationEnabled(): Boolean {
        // shared_preferences 플러그인은 안드로이드에서 "FlutterSharedPreferences" 파일에
        // "flutter." 접두사가 붙은 키로 값을 저장한다.
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getBoolean("flutter.vibration_enabled", true)
    }

    private fun vibrate() {
        if (!isVibrationEnabled()) return

        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(500)
        }
    }
override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        rotationSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isRunning) {
            baselineAngle = intent?.getDoubleExtra(EXTRA_BASELINE_ANGLE, 0.0) ?: 0.0
            angleThreshold = intent?.getDoubleExtra(EXTRA_ANGLE_THRESHOLD, 15.0) ?: 15.0

            val now = SystemClock.elapsedRealtime()
            sessionStartElapsedMillis = now
            lastAccountingMillis = now
            badPostureMillis = 0L
            continuousBadPostureMillis = 0L
            hasVibratedForCurrentStreak = false
            isRunning = true

            rotationSensor?.let {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }
            handler.post(accountingTicker)
        }

        promoteToForeground()
        return START_STICKY
    }

    override fun onDestroy() {
        accountElapsed(SystemClock.elapsedRealtime())
        handler.removeCallbacks(accountingTicker)
        sensorManager.unregisterListener(this)
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun promoteToForeground() {
        val serviceType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
        } else {
            0
        }

        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            createNotification(),
            serviceType,
        )
    }

    private fun createNotification(): Notification {
        val launchIntent = (packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        // setUsesChronometer(true)가 시스템 알림에 자동 경과 시간을 표시한다.
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("찌뿌둥 · 자세 측정 중")
            .setContentText("측정 시간이 계속 기록되고 있어요.")
            .setWhen(System.currentTimeMillis() -
                (SystemClock.elapsedRealtime() - sessionStartElapsedMillis))
            .setUsesChronometer(true)
            .setShowWhen(true)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "자세 측정 진행 알림",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "백그라운드 자세 측정 상태와 경과 시간을 표시합니다."
            }

            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }
 override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_ROTATION_VECTOR) return

        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
        SensorManager.getOrientation(rotationMatrix, orientation)
        currentAngle = Math.toDegrees(orientation[1].toDouble())
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
}
