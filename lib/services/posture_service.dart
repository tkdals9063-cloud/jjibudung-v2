import '../models/posture_data.dart';

class PostureService {
  /// 연속 나쁜 자세 진동 기준(30분)
  static const int vibrationThresholdSeconds = 1800;

  /// 현재 자세가 나쁜 자세인지 판단
  bool isBadPosture({
    required double currentAngle,
    required double baselineAngle,
    required double angleThreshold,
  }) {
    return (currentAngle - baselineAngle).abs() >= angleThreshold;
  }

  /// 1초(또는 elapsedSeconds)마다 자세 데이터 업데이트
  PostureData update({
    required PostureData data,
    required double currentAngle,
    required int elapsedSeconds,
    required double angleThreshold,
  }) {
    final bad = isBadPosture(
      currentAngle: currentAngle,
      baselineAngle: data.baselineAngle,
      angleThreshold: angleThreshold,
    );

    int totalSeconds = data.totalSeconds + elapsedSeconds;

    int badTotalSeconds = data.badTotalSeconds;

    int badContinuousSeconds = data.badContinuousSeconds;

    if (bad) {
      badTotalSeconds += elapsedSeconds;
      badContinuousSeconds += elapsedSeconds;
    } else {
      badContinuousSeconds = 0;
    }

    return data.copyWith(
      totalSeconds: totalSeconds,
      badTotalSeconds: badTotalSeconds,
      badContinuousSeconds: badContinuousSeconds,
      currentAngle: currentAngle,
      isBadPosture: bad,
    );
  }

  /// 목표 진동 여부
  bool shouldVibrate(PostureData data) {
    return data.badContinuousSeconds >= vibrationThresholdSeconds;
  }
}
