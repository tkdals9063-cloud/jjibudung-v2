/// 탐험가(목·상체)와 펫(골반·체간)을 별도의 축으로 다룬다.
///
/// 화면 분석 결과는 의학적 진단이 아니라, 이 두 축의 자세 경향을
/// 조합해 운동 우선순위를 정하기 위한 앱 내부 분류값이다.
class ExplorerCompanion {
  final String id;
  final String code;
  final String name;
  final List<String> releaseMuscles;
  final List<String> activateMuscles;
  final List<String> movementPoints;

  const ExplorerCompanion({
    required this.id,
    required this.code,
    required this.name,
    required this.releaseMuscles,
    required this.activateMuscles,
    required this.movementPoints,
  });
}

class PetCompanion {
  final String id;
  final String code;
  final String name;
  final List<String> releaseMuscles;
  final List<String> activateMuscles;
  final List<String> movementPoints;

  const PetCompanion({
    required this.id,
    required this.code,
    required this.name,
    required this.releaseMuscles,
    required this.activateMuscles,
    required this.movementPoints,
  });
}

class PostureCompanionPair {
  final ExplorerCompanion explorer;
  final PetCompanion pet;
  final String imagePath;

  const PostureCompanionPair({
    required this.explorer,
    required this.pet,
    required this.imagePath,
  });

  String get code => '${explorer.code}-${pet.code}';
  String get name => '${explorer.name} + ${pet.name}';
}

class DailyRoutineRule {
  static const int correctiveSetsPerCompanion = 3;
  static const int selectedExplorerSets = 1;
  static const int selectedPetSets = 1;
  static const int releaseMoveCount = 2;
  static const int activateMoveCount = 2;

  const DailyRoutineRule._();
}

class PostureDetectionRule {
  final String companionId;
  final List<String> requiredSignals;
  final List<String> supportingSignals;

  const PostureDetectionRule({
    required this.companionId,
    required this.requiredSignals,
    this.supportingSignals = const [],
  });
}

const explorers = <String, ExplorerCompanion>{
  'forward_head': ExplorerCompanion(
    id: 'forward_head',
    code: 'FLS',
    name: '거북목 탐험가',
    releaseMuscles: ['상부 승모근', '견갑거근', '대흉근·소흉근'],
    activateMuscles: ['긴목근·긴머리근', '능형근·중부 승모근'],
    movementPoints: ['견갑골 후인', '상완골 외회전'],
  ),
  'rested': ExplorerCompanion(
    id: 'rested',
    code: 'SSS',
    name: '쉬었음 탐험가',
    releaseMuscles: ['대흉근·소흉근', '상부 승모근·견갑거근'],
    activateMuscles: ['능형근·중부 승모근', '하부 승모근·전거근'],
    movementPoints: ['견갑골 후인·하강', '흉추 신전'],
  ),
  'tilted': ExplorerCompanion(
    id: 'tilted',
    code: 'LHE',
    name: '미어켓 탐험가',
    releaseMuscles: ['장요근', '대퇴직근'],
    activateMuscles: ['복횡근·내복사근', '대둔근'],
    movementPoints: ['갈비뼈·골반 정렬', '요추 중립', '고관절 신전'],
  ),
  'balanced': ExplorerCompanion(
    id: 'balanced',
    code: 'BPS',
    name: '바른자세 탐험가',
    releaseMuscles: [],
    activateMuscles: ['경부 심부 굴곡근', '견갑 안정화근'],
    movementPoints: ['목·어깨 중립', '편안한 호흡'],
  ),
};

const pets = <String, PetCompanion>{
  'anterior_fox': PetCompanion(
    id: 'anterior_fox',
    code: 'A',
    name: '쭉뻗 여우',
    releaseMuscles: ['장요근', '대퇴직근'],
    activateMuscles: ['대둔근·중둔근', '햄스트링'],
    movementPoints: ['고관절 신전', '골반 중립 유지'],
  ),
  'posterior_hedgehog': PetCompanion(
    id: 'posterior_hedgehog',
    code: 'P',
    name: '웅크림 고슴도치',
    releaseMuscles: ['햄스트링'],
    activateMuscles: ['요부 다열근·척추기립근', '장요근·대퇴직근'],
    movementPoints: ['골반 중립 회복', '고관절 굴곡'],
  ),
  'tilted_panda': PetCompanion(
    id: 'tilted_panda',
    code: 'T',
    name: '기우뚱 팬더',
    releaseMuscles: ['기울어진 쪽 요방형근', '긴장된 쪽 이상근'],
    activateMuscles: ['중둔근', '대둔근', '요부 다열근'],
    movementPoints: ['골반 수평', '좌우 체중 대칭'],
  ),
  'centered_penguin': PetCompanion(
    id: 'centered_penguin',
    code: 'N',
    name: '중심 펭귄',
    releaseMuscles: [],
    activateMuscles: ['대둔근·중둔근', '요부 다열근'],
    movementPoints: ['골반 중립', '양발 균등 지지'],
  ),
};

const explorerDetectionRules = <PostureDetectionRule>[
  PostureDetectionRule(
    companionId: 'forward_head',
    requiredSignals: ['좌석 뒤쪽 압력 살짝 우세', '등받이 압력 거의 없음'],
    supportingSignals: ['등받이 기울기 변화 미미'],
  ),
  PostureDetectionRule(
    companionId: 'rested',
    requiredSignals: ['좌석 뒤쪽 압력 우세', '등받이 압력 지속'],
    supportingSignals: ['등받이가 뒤로 기울어짐'],
  ),
  PostureDetectionRule(
    companionId: 'tilted',
    requiredSignals: ['좌석 앞쪽 압력 우세', '등받이 압력 낮음'],
    supportingSignals: ['등받이 기울기 변화 미미'],
  ),
];

const petDetectionRules = <PostureDetectionRule>[
  PostureDetectionRule(
    companionId: 'anterior_fox',
    requiredSignals: ['좌석 앞쪽 압력 살짝 우세', '등받이 접촉 적음'],
    supportingSignals: ['앞뒤 압력이 비교적 균형'],
  ),
  PostureDetectionRule(
    companionId: 'posterior_hedgehog',
    requiredSignals: ['좌석 뒤쪽 압력 살짝 우세', '등받이 접촉 적음'],
    supportingSignals: ['앞뒤 압력이 비교적 균형'],
  ),
  PostureDetectionRule(
    companionId: 'tilted_panda',
    requiredSignals: ['좌우 좌골 압력 차이 또는 골반 높이 차이'],
    supportingSignals: ['한쪽 체중 편향', '골반 중심선 좌우 이동'],
  ),
];

PostureCompanionPair pairForLegacyProfile(String profileId) {
  return switch (profileId) {
    'forward' => PostureCompanionPair(
      explorer: explorers['tilted']!,
      pet: pets['anterior_fox']!,
      imagePath: 'assets/characters/profile_meerkat_fox.png',
    ),
    'slouch' => PostureCompanionPair(
      explorer: explorers['rested']!,
      pet: pets['posterior_hedgehog']!,
      imagePath: 'assets/characters/profile_rested_hedgehog.png',
    ),
    'tilted' => PostureCompanionPair(
      explorer: explorers['tilted']!,
      pet: pets['tilted_panda']!,
      imagePath: 'assets/characters/profile_meerkat_panda.png',
    ),
    _ => PostureCompanionPair(
      explorer: explorers['balanced']!,
      pet: pets['centered_penguin']!,
      imagePath: 'assets/characters/profile_balanced_penguin.png',
    ),
  };
}
