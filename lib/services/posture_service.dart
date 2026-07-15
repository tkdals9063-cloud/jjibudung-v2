import '../models/posture_data.dart';

class PostureService {
  /// 기준 자세에서 벗어났다고 판단하는 각도
  static const double angleThreshold = 15.0;

  /// 현재 자세가 나쁜 자세인지 판단
  bool isBadPosture({
    required double currentAngle,
    required double baselineAngle,
  }) {
    return (currentAngle - baselineAngle).abs() >= angleThreshold;
  }

  /// 1초(또는 elapsedSeconds)마다 자세 데이터 업데이트
  PostureData update({
    required PostureData data,
    required double currentAngle,
    required int elapsedSeconds,
  }) {
    final bad = isBadPosture(
      currentAngle: currentAngle,
      baselineAngle: data.baselineAngle,
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

  /// 좋은 자세 유지 시간
  int getGoodSeconds(PostureData data) {
    return data.totalSeconds - data.badTotalSeconds;
  }

  /// 자세 유지율(%)
  double getPostureRate(PostureData data) {
    if (data.totalSeconds == 0) {
      return 100.0;
    }

    return ((data.totalSeconds - data.badTotalSeconds) /
            data.totalSeconds) *
        100;
  }

  /// 나쁜 자세 비율(%)
  double getBadPostureRate(PostureData data) {
    if (data.totalSeconds == 0) {
      return 0;
    }

    return (data.badTotalSeconds / data.totalSeconds) * 100;
  }

  /// 목표 진동 여부
  bool shouldVibrate(PostureData data) {
    return data.badContinuousSeconds >= 1800;
  }
}