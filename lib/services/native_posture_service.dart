import 'package:flutter/services.dart';

enum PostureServiceState {
  stopped,
  running,
  paused,
}

class NativePostureService {
  NativePostureService._();

  static const MethodChannel _channel =
      MethodChannel("jjibudung/posture_service");

  // ===========================================================
  // Foreground Service 시작
  // ===========================================================

  static Future<bool> start({
    required double baselineAngle,
    required double angleThreshold,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        "start",
        {
          "baselineAngle": baselineAngle,
          "angleThreshold": angleThreshold,
        },
      );

      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ===========================================================
  // Foreground Service 종료
  // ===========================================================

  static Future<bool> stop() async {
    try {
      final result =
          await _channel.invokeMethod<bool>("stop");

      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ===========================================================
  // 일시정지
  // ===========================================================

  static Future<bool> pause() async {
    try {
      final result =
          await _channel.invokeMethod<bool>("pause");

      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ===========================================================
  // 다시 시작
  // ===========================================================

  static Future<bool> resume() async {
    try {
      final result =
          await _channel.invokeMethod<bool>("resume");

      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ===========================================================
  // 기준각 변경
  // ===========================================================

  static Future<bool> updateBaseline(
      double baselineAngle) async {
    try {
      final result =
          await _channel.invokeMethod<bool>(
        "updateBaseline",
        {
          "baselineAngle": baselineAngle,
        },
      );

      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ===========================================================
  // 현재 서비스 상태
  // ===========================================================

  static Future<PostureServiceState> getState() async {
    try {
      final result =
          await _channel.invokeMethod<String>(
        "getState",
      );

      switch (result) {
        case "running":
          return PostureServiceState.running;

        case "paused":
          return PostureServiceState.paused;

        default:
          return PostureServiceState.stopped;
      }
    } on PlatformException {
      return PostureServiceState.stopped;
    }
  }

  // ===========================================================
  // 현재 기준각
  // ===========================================================

  static Future<double> getBaseline() async {
    try {
      final result =
          await _channel.invokeMethod<double>(
        "getBaseline",
      );

      return result ?? 0.0;
    } on PlatformException {
      return 0.0;
    }
  }

  // ===========================================================
  // 현재 자세각
  // ===========================================================

  static Future<double> getCurrentAngle() async {
    try {
      final result =
          await _channel.invokeMethod<double>(
        "getCurrentAngle",
      );

      return result ?? 0.0;
    } on PlatformException {
      return 0.0;
    }
  }

  // ===========================================================
  // 현재 나쁜 자세 여부
  // ===========================================================

  static Future<bool> isBadPosture() async {
    try {
      final result =
          await _channel.invokeMethod<bool>(
        "isBadPosture",
      );

      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ===========================================================
  // 현재 누적 데이터
  // ===========================================================

  static Future<Map<dynamic, dynamic>?> getSessionData() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        "getSessionData",
      );

      return result;
    } on PlatformException {
      return null;
    }
  }

  // ===========================================================
  // 서비스 연결 테스트
  // ===========================================================

  static Future<bool> ping() async {
    try {
      final result =
          await _channel.invokeMethod<String>("ping");

      return result == "pong";
    } on PlatformException {
      return false;
    }
  }
}