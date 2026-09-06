import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService._();

  // 기기 로컬에만 두는 값(계정과 무관하거나 매일 리셋되는 값)의 키.
  static const String todayStudyTimeKey = 'today_study_time';
  static const String lastStudyDateKey = 'last_study_date';
  static const String todayGoodPostureTimeKey = 'today_good_posture_time';
  static const String vibrationEnabledKey = 'vibration_enabled';
  static const String pushNotificationEnabledKey = 'push_notification_enabled';

  static const int phoneDailyStretchLimit = 1;
  static const int stretchRoutinePoint = 10;

  static SupabaseClient get _client => Supabase.instance.client;

  static String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('로그인 상태에서만 사용할 수 있어요.');
    }
    return id;
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ===========================================================
  // 공부 세션 결과 저장
  // ===========================================================

  static Future<void> saveStudyResult({
    required int studySeconds,
    required int goodPostureSeconds,
    required int earnedPoint,
    required double postureRate,
  }) async {
    if (studySeconds <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(DateTime.now());

    if (prefs.getString(lastStudyDateKey) != todayKey) {
      await prefs.setInt(todayStudyTimeKey, 0);
      await prefs.setInt(todayGoodPostureTimeKey, 0);
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

    await _client.rpc('save_study_result', params: {
      'p_study_seconds': studySeconds,
      'p_good_posture_seconds': goodPostureSeconds,
      'p_earned_point': earnedPoint,
      'p_posture_rate': postureRate,
    });
  }

  static Future<List<bool>> loadCurrentWeekUsage() async {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    final sunday = monday.add(const Duration(days: 6));

    final rows = await _client
        .from('usage_logs')
        .select('used_date')
        .eq('user_id', _uid)
        .gte('used_date', _dateKey(monday))
        .lte('used_date', _dateKey(sunday));

    final dates = (rows as List)
        .map((row) => row['used_date'] as String)
        .toSet();

    return List<bool>.generate(7, (index) {
      return dates.contains(_dateKey(monday.add(Duration(days: index))));
    });
  }

  // ===========================================================
  // 자세 프로필
  // ===========================================================

  // 기준 자세 측정이 끝나면 자세 친구를 해금한다.
  // 사용자는 이 순간 바른 자세로 앉아 있으므로 초기 타입은 균형형으로 둔다.
  static Future<void> saveInitialPostureProfile({
    required double baselineAngle,
    required double baselineRoll,
  }) async {
    await _client.from('profiles').update({
      'initial_baseline_angle': baselineAngle,
      'initial_baseline_roll': baselineRoll,
      'posture_profile_id': 'balanced',
    }).eq('user_id', _uid);
  }

  static Future<bool> loadHasInitialPostureProfile() async {
    final row = await _client
        .from('profiles')
        .select('initial_baseline_angle')
        .eq('user_id', _uid)
        .maybeSingle();
    return row != null && row['initial_baseline_angle'] != null;
  }

  // 현재 센서는 기준 자세에서 벗어난 빈도를 측정한다.
  // 따라서 의학적 진단이 아니라 앱 안의 '자세 친구' 표시용 경향값이다.
  static Future<void> updatePostureProfileFromRate({
    required double postureRate,
  }) async {
    final profileId = postureRate >= 85
        ? 'balanced'
        : postureRate >= 65
        ? 'forward'
        : 'slouch';

    await _client
        .from('profiles')
        .update({'posture_profile_id': profileId})
        .eq('user_id', _uid);
  }

  static Future<String> loadPostureProfileId() async {
    final row = await _client
        .from('profiles')
        .select('posture_profile_id')
        .eq('user_id', _uid)
        .maybeSingle();
    return (row?['posture_profile_id'] as String?) ?? 'balanced';
  }

  // ===========================================================
  // 휴대폰 스트레칭 루틴
  // ===========================================================

  /// 오늘 완료한 휴대폰 스트레칭 루틴 수(0 또는 1).
  static Future<int> loadTodayStretchRoutineCount() async {
    final rows = await _client
        .from('stretch_completions')
        .select('completed_date')
        .eq('user_id', _uid)
        .eq('completed_date', _dateKey(DateTime.now()));
    return (rows as List).length;
  }

  /// 루틴 전체를 끝냈을 때만 호출한다. 오늘 이미 완료했다면 false를 반환한다.
  static Future<bool> completePhoneStretchRoutine() async {
    try {
      await _client.rpc('complete_stretch_routine');
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // (user_id, completed_date) 기본키 충돌 = 오늘 이미 완료함
        return false;
      }
      rethrow;
    }
  }

  // ===========================================================
  // 오늘자 카운터 (로컬 전용, 매일 리셋)
  // ===========================================================

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

  // ===========================================================
  // 계정 데이터 조회 (profiles)
  // ===========================================================

  static Future<int> loadPoint() async {
    final row = await _client
        .from('profiles')
        .select('point')
        .eq('user_id', _uid)
        .maybeSingle();
    return (row?['point'] as int?) ?? 0;
  }

  static Future<int> loadStreak() async {
    final row = await _client
        .from('profiles')
        .select('streak')
        .eq('user_id', _uid)
        .maybeSingle();
    return (row?['streak'] as int?) ?? 0;
  }

  static Future<double> loadPostureRate() async {
    final row = await _client
        .from('profiles')
        .select('posture_rate')
        .eq('user_id', _uid)
        .maybeSingle();
    return (row?['posture_rate'] as num?)?.toDouble() ?? 100.0;
  }

  static Future<int> loadTotalStudyTime() async {
    final row = await _client
        .from('profiles')
        .select('total_study_time_seconds')
        .eq('user_id', _uid)
        .maybeSingle();
    return (row?['total_study_time_seconds'] as int?) ?? 0;
  }

  static Future<int> loadTotalGoodPostureTime() async {
    final row = await _client
        .from('profiles')
        .select('total_good_posture_time_seconds')
        .eq('user_id', _uid)
        .maybeSingle();
    return (row?['total_good_posture_time_seconds'] as int?) ?? 0;
  }

  /// 포인트 차감(리워드 교환). 잔액이 부족하면 [PostgrestException]을 던진다.
  static Future<int> spendPoints(int amount) async {
    final row = await _client.rpc(
      'spend_points',
      params: {'p_amount': amount},
    );
    return (row as Map)['point'] as int;
  }

  // ===========================================================
  // 설정 (로컬 전용, 기기별로 달라도 되는 값)
  // ===========================================================

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
