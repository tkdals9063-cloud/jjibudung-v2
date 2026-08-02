import 'package:flutter/foundation.dart';

class AppController extends ChangeNotifier {
  bool _isWorking = false;

  bool get isWorking => _isWorking;

  void startWork() {
    _isWorking = true;
    notifyListeners();
  }

  void stopWork() {
    _isWorking = false;
    notifyListeners();
  }
}