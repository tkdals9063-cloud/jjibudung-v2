package com.example.jjibudung_v2

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

class PostureStreamHandler : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    private val handler = Handler(Looper.getMainLooper())

    private val updateTask = object : Runnable {
        override fun run() {

            eventSink?.success(PostureService.currentAngle)

            handler.postDelayed(this, 100)
        }
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {

        eventSink = events

        handler.post(updateTask)
    }

    override fun onCancel(arguments: Any?) {

        handler.removeCallbacks(updateTask)

        eventSink = null
    }
}