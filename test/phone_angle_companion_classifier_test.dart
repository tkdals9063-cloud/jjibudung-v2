import 'package:flutter_test/flutter_test.dart';
import 'package:jjibudung_v2/services/phone_angle_companion_classifier.dart';

void main() {
  test('upright phone keeps balanced penguin', () {
    final selection = PhoneAngleCompanionClassifier.fromAngles(
      pitch: -88,
      roll: 2,
    );
    expect(selection.explorerId, 'balanced');
    expect(selection.petId, 'centered_penguin');
  });

  test('front/back tilt and lateral tilt select supported pairs', () {
    final fox = PhoneAngleCompanionClassifier.fromAngles(
      pitch: -68,
      roll: 2,
    );
    expect((fox.explorerId, fox.petId), ('tilted', 'anterior_fox'));

    final hedgehog = PhoneAngleCompanionClassifier.fromAngles(
      pitch: -55,
      roll: 2,
    );
    expect(
      (hedgehog.explorerId, hedgehog.petId),
      ('forward_head', 'posterior_hedgehog'),
    );

    final panda = PhoneAngleCompanionClassifier.fromAngles(
      pitch: -68,
      roll: 14,
    );
    expect((panda.explorerId, panda.petId), ('tilted', 'tilted_panda'));
  });

  test('reversed phone orientation uses the same zones', () {
    final selection = PhoneAngleCompanionClassifier.fromAngles(
      pitch: 77,
      roll: -179,
    );
    expect(
      (selection.explorerId, selection.petId),
      ('rested', 'posterior_hedgehog'),
    );
  });

  test('screen toward body and top downward keeps equivalent posture zones', () {
    for (final (pitch, roll) in [(-88.0, 2.0), (-68.0, 2.0), (-55.0, 14.0)]) {
      final usual = PhoneAngleCompanionClassifier.fromAngles(
        pitch: pitch,
        roll: roll,
      );
      final reversed = PhoneAngleCompanionClassifier.fromAngles(
        pitch: -pitch,
        roll: roll - 180,
      );
      expect((reversed.explorerId, reversed.petId),
          (usual.explorerId, usual.petId));
    }
  });
}
