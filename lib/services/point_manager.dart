import 'package:shared_preferences/shared_preferences.dart';

class PointManager {
  static const String _pointKey = "user_points";

  /// 현재 포인트
  Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_pointKey) ?? 0;
  }

  /// 포인트 저장
  Future<void> setPoints(int point) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_pointKey, point);
  }

  /// 포인트 추가
  Future<int> addPoints(int point) async {
    final prefs = await SharedPreferences.getInstance();

    final current = prefs.getInt(_pointKey) ?? 0;

    final total = current + point;

    await prefs.setInt(_pointKey, total);

    return total;
  }

  /// 포인트 차감
  Future<int> usePoints(int point) async {
    final prefs = await SharedPreferences.getInstance();

    final current = prefs.getInt(_pointKey) ?? 0;

    int total = current - point;

    if (total < 0) {
      total = 0;
    }

    await prefs.setInt(_pointKey, total);

    return total;
  }

  /// 포인트 초기화
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_pointKey);
  }
}
