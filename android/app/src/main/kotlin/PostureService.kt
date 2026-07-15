package com.example.jjibudung_v2

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class PostureService : Service(), SensorEventListener {

    companion object {
        const val CHANNEL_ID = "posture_service_channel"
        const val NOTIFICATION_ID = 1001

        @Volatile
        var currentAngle = 0.0
    }

    // ===========================================================
    // Sensor
    // ===========================================================

    private lateinit var sensorManager: SensorManager

    private var rotationSensor: Sensor? = null

    private val rotationMatrix = FloatArray(9)

    private val orientation = FloatArray(3)

    // ===========================================================
    // Lifecycle
    // ===========================================================

    override fun onCreate() {
        super.onCreate()

        createNotificationChannel()

        sensorManager =
            getSystemService(Context.SENSOR_SERVICE)
                    as SensorManager

        rotationSensor =
            sensorManager.getDefaultSensor(
                Sensor.TYPE_ROTATION_VECTOR
            )
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        startForeground(
            NOTIFICATION_ID,
            createNotification()
        )

        rotationSensor?.let {

            sensorManager.registerListener(
                this,
                it,
                SensorManager.SENSOR_DELAY_GAME
            )

        }

        return START_STICKY
    }

    override fun onDestroy() {

        sensorManager.unregisterListener(this)

        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    // ===========================================================
    // Notification
    // ===========================================================

    private fun createNotification(): Notification {

        return NotificationCompat.Builder(
            this,
            CHANNEL_ID
        )
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("찌뿌둥")
            .setContentText("자세를 측정하는 중입니다.")
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val channel = NotificationChannel(
                CHANNEL_ID,
                "Posture Service",
                NotificationManager.IMPORTANCE_LOW
            )

            val manager =
                getSystemService(NotificationManager::class.java)

            manager.createNotificationChannel(channel)
        }
    }

    // ===========================================================
    // Sensor Listener
    // ===========================================================

    override fun onSensorChanged(event: SensorEvent?) {

        if (event == null) return

        if (event.sensor.type != Sensor.TYPE_ROTATION_VECTOR) return

        SensorManager.getRotationMatrixFromVector(
            rotationMatrix,
            event.values
        )

        SensorManager.getOrientation(
            rotationMatrix,
            orientation
        )

        val pitch =
            Math.toDegrees(
                orientation[1].toDouble()
            )

        currentAngle = pitch
    }

    override fun onAccuracyChanged(
        sensor: Sensor?,
        accuracy: Int
    ) {
        // 사용하지 않음
    }
}