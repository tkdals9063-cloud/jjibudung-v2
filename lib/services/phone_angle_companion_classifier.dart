import 'dart:math' as math;

import '../models/posture_companion.dart';

/// A phone-in-pocket angle estimate. It cannot measure head position or seat
/// pressure, so the result is an app display tendency, not a posture diagnosis.
class PhoneAngleCompanionClassifier {
  const PhoneAngleCompanionClassifier._();

  static CompanionSelection fromAngles({
    required double pitch,
    required double roll,
  }) {
    if (!pitch.isFinite || !roll.isFinite) return CompanionSelection.balanced;

    // Upright phones read near +/-90 degrees of pitch. Either screen direction
    // works, and roll near +/-180 is equivalent to level for a reversed phone.
    final frontBackTilt = (90 - pitch.abs()).abs();
    final absoluteRoll = roll.abs() % 180;
    final lateralTilt = math.min(
      absoluteRoll,
      180 - absoluteRoll,
    );

    String explorerId;
    String petId;
    if (frontBackTilt >= 30) {
      explorerId = 'forward_head';
      petId = 'posterior_hedgehog';
    } else if (frontBackTilt >= 18) {
      explorerId = 'tilted';
      petId = 'anterior_fox';
    } else if (frontBackTilt >= 10) {
      explorerId = 'rested';
      petId = 'posterior_hedgehog';
    } else if (lateralTilt >= 10) {
      explorerId = 'rested';
      petId = 'tilted_panda';
    } else {
      return CompanionSelection.balanced;
    }

    if (lateralTilt >= 10) petId = 'tilted_panda';
    return CompanionSelection.fromIds(explorerId, petId);
  }
}
