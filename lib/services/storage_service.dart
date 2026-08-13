import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static const String todayStudyTimeKey = 'today_study_time';
  static const String totalStudyTimeKey = 'total_study_time';
  static const String pointKey = 'point';
  static const String postureRateKey = 'posture_rate';
  static const String streakKey = 'study_streak';
  static const String lastStudyDateKey = 'last_study_date';
  static const String todayGoodPostureTimeKey = 'today_good_posture_time';
  static const String totalGoodPostureTimeKey = 'total_good_posture_time';
  static const String weekUsageDatesKey = 'week_usage_dates';
  static const String hasInitialPostureProfileKey =
      'has_initial_posture_profile';
  static const String initialBaselineAngleKey = 'initial_baseline_angle';
  static const String postureProfileIdKey = 'posture_profile_id';
  static const String vibrationEnabledKey = 'vibration_enabled';
  static const String pushNotificationEnabledKey = 'push_notification_enabled';

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _saveUsageDate(
    SharedPreferences prefs,
    String todayKey,
  ) async {
    final dates = prefs.getStringList(weekUsageDatesKey) ?? <String>[];

    if (!dates.contains(todayKey)) {
      dates.add(todayKey);
    }

    final limit = DateTime.now().subtract(const Duration(days: 90));
    dates.removeWhere((value) {
      final date = DateTime.tryParse(value);
      return date == null || date.isBefore(limit);
    });

    await prefs.setStringList(weekUsageDatesKey, dates);
  }

  static Future<void> saveStudyResult({
    required int studySeconds,
    required int goodPostureSeconds,
    required int earnedPoint,
    required double postureRate,
  }) async {
    if (studySeconds <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final lastStudyDate = prefs.getString(lastStudyDateKey);

    if (lastStudyDate != todayKey) {
      await prefs.setInt(todayStudyTimeKey, 0);
      await prefs.setInt(todayGoodPostureTimeKey, 0);

      var streak = prefs.getInt(streakKey) ?? 0;
      final last = lastStudyDate == null
          ? null
          : DateTime.tryParse(lastStudyDate);

      if (last == null) {
        streak = 1;
      } else if (DateTime(
            now.year,
            now.month,
            now.day,
          ).difference(DateTime(last.year, last.month, last.day)).inDays ==
          1) {
        streak++;
      } else {
        streak = 1;
      }

      await prefs.setInt(streakKey, streak);
      await prefs.setString(lastStudyDateKey, todayKey);
    }

    final todayStudy = prefs.getInt(todayStudyTimeKey) ?? 0;
    final todayGood = prefs.getInt(todayGoodPostureTimeKey) ?? 0;
    final totalStudy = prefs.getInt(totalStudyTimeKey) ?? 0;
    final totalGood = prefs.getInt(totalGoodPostureTimeKey) ?? 0;
    final point = prefs.getInt(pointKey) ?? 0;

    await prefs.setInt(todayStudyTimeKey, todayStudy + studySeconds);
    await prefs.setInt(todayGoodPostureTimeKey, todayGood + goodPostureSeconds);
    await prefs.setInt(totalStudyTimeKey, totalStudy + studySeconds);
    await prefs.setInt(totalGoodPostureTimeKey, totalGood + goodPostureSeconds);
    await prefs.setInt(pointKey, point + earnedPoint);
    await prefs.setDouble(postureRateKey, postureRate);
    await _saveUsageDate(prefs, todayKey);
  }

  static Future<List<bool>> loadCurrentWeekUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final dates = (prefs.getStringList(weekUsageDatesKey) ?? <String>[])
        .toSet();
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));

    return List<bool>.generate(7, (index) {
      return dates.contains(_dateKey(monday.add(Duration(days: index))));
    });
  }

  // 기준 자세 측정이 끝나면 자세 친구를 해금한다.
  // 사용자는 이 순간 바른 자세로 앉아 있으므로 초기 타입은 균형형으로 둔다.
  static Future<void> saveInitialPostureProfile({
    required double baselineAngle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hasInitialPostureProfileKey, true);
    await prefs.setDouble(initialBaselineAngleKey, baselineAngle);
    await prefs.setString(postureProfileIdKey, 'balanced');
  }

  static Future<bool> loadHasInitialPostureProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(hasInitialPostureProfileKey) ?? false;
  }

  // 현재 센서는 기준 자세에서 벗어난 빈도를 측정한다.
  // 따라서 의학적 진단이 아니라 앱 안의 '자세 친구' 표시용 경향값이다.
  static Future<void> updatePostureProfileFromRate({
    required double postureRate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profileId = postureRate >= 85
        ? 'balanced'
        : postureRate >= 65
        ? 'forward'
        : 'slouch';
    await prefs.setString(postureProfileIdKey, profileId);
  }

  static Future<String> loadPostureProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(postureProfileIdKey) ?? 'balanced';
  }

  static Future<int> loadTodayStudyTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(lastStudyDateKey) != _dateKey(DateTime.now())) return 0;
    return prefs.getInt(todayStudyTimeKey) ?? 0;
  }

  static Future<int> loadTodayGoodPostureTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(lastStudyDateKey) != _dateKey(DateTime.now())) return 0;
    return prefs.getInt(todayGoodPostureTimeKey) ?? 0;
  }

  static Future<int> loadPoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(pointKey) ?? 0;
  }

  static Future<int> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(streakKey) ?? 0;
  }

  static Future<double> loadPostureRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(postureRateKey) ?? 100.0;
  }

  static Future<int> loadTotalStudyTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(totalStudyTimeKey) ?? 0;
  }

  static Future<int> loadTotalGoodPostureTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(totalGoodPostureTimeKey) ?? 0;
  }

  static Future<bool> loadVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(vibrationEnabledKey) ?? true;
  }

  static Future<void> saveVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(vibrationEnabledKey, enabled);
  }

  static Future<bool> loadPushNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(pushNotificationEnabledKey) ?? true;
  }

  static Future<void> savePushNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pushNotificationEnabledKey, enabled);
  }
}
