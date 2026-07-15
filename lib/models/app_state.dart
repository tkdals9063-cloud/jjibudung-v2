class AppState {
  final int point;

  final int xp;

  final int level;

  final int todayStudySeconds;

  final double postureRate;

  final int streak;

  const AppState({
    required this.point,
    required this.xp,
    required this.level,
    required this.todayStudySeconds,
    required this.postureRate,
    required this.streak,
  });

  factory AppState.initial() {
    return const AppState(
      point: 0,
      xp: 0,
      level: 1,
      todayStudySeconds: 0,
      postureRate: 100,
      streak: 0,
    );
  }

  AppState copyWith({
    int? point,
    int? xp,
    int? level,
    int? todayStudySeconds,
    double? postureRate,
    int? streak,
  }) {
    return AppState(
      point: point ?? this.point,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      todayStudySeconds:
          todayStudySeconds ?? this.todayStudySeconds,
      postureRate:
          postureRate ?? this.postureRate,
      streak:
          streak ?? this.streak,
    );
  }
}