import 'package:flutter/foundation.dart';

import '../models/posture_data.dart';
import '../services/posture_service.dart';

class PostureController extends ChangeNotifier {
  final PostureService _service = PostureService();

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

  void updateAngle({
  required double angle,
  required double angleThreshold,
}) {
  _data = _data.copyWith(
    currentAngle: angle,
    isBadPosture: _service.isBadPosture(
      currentAngle: angle,
      baselineAngle: _data.baselineAngle,
      angleThreshold: angleThreshold,
    ),
  );

  notifyListeners();
}

 void tick({
  required double angleThreshold,
}) {
    if (!_data.isWorking) return;

    _data = _service.update(
  data: _data,
  currentAngle: _data.currentAngle,
  elapsedSeconds: 1,
  angleThreshold: angleThreshold,
);

    notifyListeners();
  }

  bool shouldVibrate() {
    return _service.shouldVibrate(_data);
  }

  void reset() {
    _data = PostureData.initial();
    notifyListeners();
  }
}