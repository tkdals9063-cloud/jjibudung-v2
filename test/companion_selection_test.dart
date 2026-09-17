import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jjibudung_v2/models/posture_companion.dart';
import 'package:jjibudung_v2/models/posture_profile_info.dart';

void main() {
  test(
    'balanced explorer always pairs with centered penguin',
    () {
      final selection = CompanionSelection.fromIds(
        'balanced',
        'centered_penguin',
      );
      expect(selection.explorerId, 'balanced');
      expect(selection.petId, 'centered_penguin');
      expect(
        CompanionSelection.fromIds('balanced', 'tilted_panda').petId,
        'centered_penguin',
      );
    },
  );

  test('every supported pair has matching labels and available images', () {
    for (final explorerId in explorers.keys) {
      for (final petId in pets.keys) {
        final selection = CompanionSelection.fromIds(explorerId, petId);
        final info = postureProfileInfoForSelection(selection);
        expect(info.explorerName, selection.pair.explorer.name);
        expect(info.petName, selection.pair.pet.name);
        expect(info.code, selection.pair.code);
        expect(selection.seatedImagePath, isNotNull);
        expect(selection.standingImagePath, isNotNull);
        expect(File(selection.seatedImagePath!).existsSync(), isTrue);
        expect(File(selection.standingImagePath!).existsSync(), isTrue);
      }
    }
  });

  test('unsupported combinations normalize to the explorer default', () {
    expect(CompanionSelection.fromIds('balanced', 'tilted_panda').pair.code,
        'BPS-N');
    expect(CompanionSelection.fromIds('forward_head', 'anterior_fox').pair.code,
        'FLS-P');
    expect(CompanionSelection.fromIds('tilted', 'posterior_hedgehog').pair.code,
        'LHE-A');
  });

  test('legacy posture IDs map to the same persisted pair IDs', () {
    expect(CompanionSelection.fromLegacy('forward').pair.code, 'FLS-P');
    expect(CompanionSelection.fromLegacy('slouch').pair.code, 'SSS-P');
    expect(CompanionSelection.fromLegacy('tilted').pair.code, 'LHE-A');
    expect(CompanionSelection.fromLegacy('balanced').pair.code, 'BPS-N');
  });

  test('agreed pairs use the correct seated and standing assets', () {
    final balanced = CompanionSelection.fromLegacy('balanced');
    expect(balanced.seatedImagePath,
        'assets/characters/profile_balanced_penguin_seated.png');
    expect(balanced.standingImagePath,
        'assets/characters/profile_balanced_penguin.png');

    final meerkat = CompanionSelection.fromLegacy('tilted');
    expect(meerkat.seatedImagePath,
        'assets/characters/profile_meerkat_fox.png');
    expect(meerkat.standingImagePath,
        'assets/characters/profile_meerkat_fox_standing.png');

    final turtle = CompanionSelection.fromLegacy('forward');
    expect(turtle.seatedImagePath,
        'assets/characters/profile_turtle_hedgehog.png');
    expect(turtle.standingImagePath,
        'assets/characters/profile_turtle_hedgehog_standing.png');

    final rested = CompanionSelection.fromLegacy('slouch');
    expect(rested.seatedImagePath,
        'assets/characters/profile_rested_hedgehog.png');
    expect(rested.standingImagePath,
        'assets/characters/profile_rested_hedgehog_standing.png');

    for (final explorerId in explorers.keys.where((id) => id != 'balanced')) {
      final panda = CompanionSelection.fromIds(explorerId, 'tilted_panda');
      expect(panda.petId, 'tilted_panda');
      expect(panda.seatedImagePath, isNotNull);
      expect(panda.standingImagePath, isNotNull);
    }
  });
}
