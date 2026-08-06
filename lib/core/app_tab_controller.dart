import 'package:flutter/foundation.dart';

class AppTabController {
  AppTabController._();

  static final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  static void openStretchTab() {
    currentIndex.value = 2;
  }
}
