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
  static const String initialBaselineRollKey = 'initial_baseline_roll';
  static const String postureProfileIdKey = 'posture_profile_id';
  static const String vibrationEnabledKey = 'vibration_enabled';
  static const String pushNotificationEnabledKey = 'push_notification_enabled';
  static const String todayStretchRoutineCountKey =
      'today_stretch_routine_count';
  static const String stretchRoutineDateKey = 'stretch_routine_date';

  static const int phoneDailyStretchLimit = 1;
  static const int stretchRoutinePoint = 10;

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
    if (studySeconds <= 0) {
      return;
    }

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

    await prefs.setInt(
      todayStudyTimeKey,
      (prefs.getInt(todayStudyTimeKey) ?? 0) + studySeconds,
    );
    await prefs.setInt(
      todayGoodPostureTimeKey,
      (prefs.getInt(todayGoodPostureTimeKey) ?? 0) + goodPostureSeconds,
    );
    await prefs.setInt(
      totalStudyTimeKey,
      (prefs.getInt(totalStudyTimeKey) ?? 0) + studySeconds,
    );
    await prefs.setInt(
      totalGoodPostureTimeKey,
      (prefs.getInt(totalGoodPostureTimeKey) ?? 0) + goodPostureSeconds,
    );
    await prefs.setInt(pointKey, (prefs.getInt(pointKey) ?? 0) + earnedPoint);
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

  static Future<void> saveInitialPostureProfile({
    required double baselineAngle,
    required double baselineRoll,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hasInitialPostureProfileKey, true);
    await prefs.setDouble(initialBaselineAngleKey, baselineAngle);
    await prefs.setDouble(initialBaselineRollKey, baselineRoll);
    await prefs.setString(postureProfileIdKey, 'balanced');
  }

  static Future<bool> loadHasInitialPostureProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(hasInitialPostureProfileKey) ?? false;
  }

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

  /// 오늘 완료한 휴대폰 스트레칭 루틴 수. 날짜가 다르면 0회다.
  static Future<int> loadTodayStretchRoutineCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(stretchRoutineDateKey) != _dateKey(DateTime.now())) {
      return 0;
    }
    return prefs.getInt(todayStretchRoutineCountKey) ?? 0;
  }

  /// 루틴 전체를 끝냈을 때만 호출한다. 제한을 넘으면 false를 반환한다.
  static Future<bool> completePhoneStretchRoutine() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(DateTime.now());
    var completed = prefs.getString(stretchRoutineDateKey) == todayKey
        ? prefs.getInt(todayStretchRoutineCountKey) ?? 0
        : 0;

    if (completed >= phoneDailyStretchLimit) {
      return false;
    }

    completed++;
    await prefs.setString(stretchRoutineDateKey, todayKey);
    await prefs.setInt(todayStretchRoutineCountKey, completed);
    await prefs.setInt(
      pointKey,
      (prefs.getInt(pointKey) ?? 0) + stretchRoutinePoint,
    );
    return true;
  }

  static Future<int> loadTodayStudyTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(lastStudyDateKey) != _dateKey(DateTime.now())) {
      return 0;
    }
    return prefs.getInt(todayStudyTimeKey) ?? 0;
  }

  static Future<int> loadTodayGoodPostureTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(lastStudyDateKey) != _dateKey(DateTime.now())) {
      return 0;
    }
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
