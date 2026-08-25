import 'dart:async';

import 'package:flutter/services.dart';

enum PostureServiceState {
  stopped,
  starting,
  running,
  paused,
  calibrating,
  error,
}

class PostureAngles {
  final double pitch;
  final double roll;

  const PostureAngles({required this.pitch, required this.roll});

  factory PostureAngles.fromEvent(dynamic event) {
    if (event is Map) {
      return PostureAngles(
        pitch: (event['pitch'] as num?)?.toDouble() ?? 0.0,
        roll: (event['roll'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return PostureAngles(pitch: (event as num).toDouble(), roll: 0.0);
  }
}

class NativePostureService {
  NativePostureService._();

  static const MethodChannel _channel = MethodChannel(
    'jjibudung/posture_service',
  );

  static const EventChannel _eventChannel = EventChannel(
    'jjibudung/posture_stream',
  );

  static Stream<PostureAngles> get angleStream {
    return _eventChannel.receiveBroadcastStream().map(PostureAngles.fromEvent);
  }

  static Future<bool> start({
    required double baselinePitch,
    required double baselineRoll,
    required double pitchThreshold,
    required double rollThreshold,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('start', {
        'baselinePitch': baselinePitch,
        'baselineRoll': baselineRoll,
        'pitchThreshold': pitchThreshold,
        'rollThreshold': rollThreshold,
      });

      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      return await _channel.invokeMethod<bool>('stop') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> pause() async {
    try {
      return await _channel.invokeMethod<bool>('pause') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> resume() async {
    try {
      return await _channel.invokeMethod<bool>('resume') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> updateBaseline({
    required double baselinePitch,
    required double baselineRoll,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('updateBaseline', {
            'baselinePitch': baselinePitch,
            'baselineRoll': baselineRoll,
          }) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  static Future<PostureServiceState> getState() async {
    try {
      final state = await _channel.invokeMethod<String>('getState');

      return state == 'running'
          ? PostureServiceState.running
          : state == 'paused'
          ? PostureServiceState.paused
          : PostureServiceState.stopped;
    } on PlatformException {
      return PostureServiceState.stopped;
    }
  }

  static Future<double> getCurrentAngle() async {
    try {
      return await _channel.invokeMethod<double>('getCurrentAngle') ?? 0.0;
    } on PlatformException {
      return 0.0;
    }
  }

  static Future<double> getBaseline() async {
    try {
      return await _channel.invokeMethod<double>('getBaseline') ?? 0.0;
    } on PlatformException {
      return 0.0;
    }
  }

  static Future<bool> isBadPosture() async {
    try {
      return await _channel.invokeMethod<bool>('isBadPosture') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<Map<dynamic, dynamic>?> getSessionData() async {
    try {
      return await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getSessionData',
      );
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> ping() async {
    try {
      return await _channel.invokeMethod<String>('ping') == 'pong';
    } on PlatformException {
      return false;
    }
  }
}
