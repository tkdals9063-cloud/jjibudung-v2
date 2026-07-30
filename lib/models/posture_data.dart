class PostureData {
  final int totalSeconds;
  final int badTotalSeconds;
  final int badContinuousSeconds;

  final double currentAngle;
  final double baselineAngle;

  final bool isBadPosture;
  final bool isWorking;

  const PostureData({
    required this.totalSeconds,
    required this.badTotalSeconds,
    required this.badContinuousSeconds,
    required this.currentAngle,
    required this.baselineAngle,
    required this.isBadPosture,
    required this.isWorking,
  });

  factory PostureData.initial() {
    return const PostureData(
      totalSeconds: 0,
      badTotalSeconds: 0,
      badContinuousSeconds: 0,
      currentAngle: 0,
      baselineAngle: 0,
      isBadPosture: false,
      isWorking: false,
    );
  }

    PostureData copyWith({
    int? totalSeconds,
    int? badTotalSeconds,
    int? badContinuousSeconds,
    double? currentAngle,
    double? baselineAngle,
    bool? isBadPosture,
    bool? isWorking,
  }) {
    return PostureData(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      badTotalSeconds: badTotalSeconds ?? this.badTotalSeconds,
      badContinuousSeconds:
          badContinuousSeconds ?? this.badContinuousSeconds,
      currentAngle: currentAngle ?? this.currentAngle,
      baselineAngle: baselineAngle ?? this.baselineAngle,
      isBadPosture: isBadPosture ?? this.isBadPosture,
      isWorking: isWorking ?? this.isWorking,
    );
  }

  /// 좋은 자세 유지 시간
  int get goodSeconds => totalSeconds - badTotalSeconds;

  /// 자세 유지율(%)
  double get postureRate {
    if (totalSeconds == 0) return 100.0;

    return ((totalSeconds - badTotalSeconds) / totalSeconds) * 100;
  }

  /// 나쁜 자세 비율(%)
  double get badPostureRate {
    if (totalSeconds == 0) return 0;

    return (badTotalSeconds / totalSeconds) * 100;
  }
}