import 'package:flutter/foundation.dart';
import '../models/posture_data.dart';

class PostureController extends ChangeNotifier {
  PostureData _data = PostureData.initial();

  PostureData get data => _data;

  void startWork({
    required double baselineAngle,
  }) {
    _data = PostureData(
      totalSeconds: 0,
      badTotalSeconds: 0,
      badContinuousSeconds: 0,
      currentAngle: baselineAngle,
      baselineAngle: baselineAngle,
      isBadPosture: false,
      isWorking: true,
    );

    notifyListeners();
  }

  void stopWork() {
    _data = _data.copyWith(
      isWorking: false,
    );

    notifyListeners();
  }

  void updateAngle(double angle) {
    final diff = (angle - _data.baselineAngle).abs();

    _data = _data.copyWith(
      currentAngle: angle,
      isBadPosture: diff >= 15,
    );

    notifyListeners();
  }

  void tick() {
    if (!_data.isWorking) return;

    _data = _data.copyWith(
      totalSeconds: _data.totalSeconds + 1,
      badTotalSeconds: _data.isBadPosture
          ? _data.badTotalSeconds + 1
          : _data.badTotalSeconds,
      badContinuousSeconds: _data.isBadPosture
          ? _data.badContinuousSeconds + 1
          : 0,
    );

    notifyListeners();
  }

  void reset() {
    _data = PostureData.initial();
    notifyListeners();
  }
}