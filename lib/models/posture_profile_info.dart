class PostureProfileInfo {
  final String code;
  final String explorerName;
  final String petName;
  final String imagePath;
  final String brief;
  final String posture;
  final String habit;
  final String discomfort;

  const PostureProfileInfo({
    required this.code,
    required this.explorerName,
    required this.petName,
    required this.imagePath,
    required this.brief,
    required this.posture,
    required this.habit,
    required this.discomfort,
  });
}

PostureProfileInfo postureProfileInfoFor(String profileId) {
  return switch (profileId) {
    'forward' => const PostureProfileInfo(
      code: 'FLS-A',
      explorerName: '거북목 탐험가',
      petName: '앞기울임 여우',
      imagePath: 'assets/characters/profile_forward_fox.png',
      brief: '앞으로 집중하는 습관이 있는 몰입형이에요.',
      posture: '화면을 볼 때 턱과 어깨가 앞쪽으로 나오고, 허리가 과하게 꺾일 수 있어요.',
      habit: '목을 앞으로 빼고 앉거나, 한 자세로 화면을 오래 내려다보는 습관이 나타날 수 있어요.',
      discomfort: '오래 이어지면 목·어깨와 허리 주변이 뻐근하게 느껴질 수 있어요.',
    ),
    'slouch' => const PostureProfileInfo(
      code: 'SSS-P',
      explorerName: '쉬었음 탐험가',
      petName: '뒤말림 고슴도치',
      imagePath: 'assets/characters/profile_rested_hedgehog.png',
      brief: '편하게 기대어 쉬는 습관이 있는 휴식형이에요.',
      posture: '등이 둥글어지고 가슴이 닫히며, 골반이 의자 앞쪽으로 미끄러질 수 있어요.',
      habit: '엉덩이를 의자 끝에 걸치거나 어깨를 안쪽으로 말고 앉는 습관이 나타날 수 있어요.',
      discomfort: '오래 이어지면 등·어깨와 골반 주변이 답답하거나 뻐근하게 느껴질 수 있어요.',
    ),
    'tilted' => const PostureProfileInfo(
      code: 'ATS-P',
      explorerName: '삐딱 탐험가',
      petName: '기우뚱 팬더',
      imagePath: 'assets/characters/profile_tilted_panda.png',
      brief: '한쪽으로 기울어 쉬기 쉬운 균형 탐색형이에요.',
      posture: '머리·어깨·골반이 한쪽으로 기울거나, 양쪽에 걸리는 힘이 달라질 수 있어요.',
      habit: '다리를 꼬거나 한쪽 팔에 기대고, 같은 방향으로만 몸을 기울이는 습관이 나타날 수 있어요.',
      discomfort: '오래 이어지면 한쪽 목·어깨·골반에 피로가 더 크게 느껴질 수 있어요.',
    ),
    _ => const PostureProfileInfo(
      code: 'BPS-N',
      explorerName: '바른자세 탐험가',
      petName: '중심 펭귄',
      imagePath: 'assets/characters/profile_balanced_penguin.png',
      brief: '몸의 중심을 편안하게 지키는 균형형이에요.',
      posture: '머리·어깨·골반이 크게 한쪽으로 쏠리지 않고 편안한 균형을 유지해요.',
      habit: '자세를 자주 다시 맞추고, 몸에 힘을 과하게 주지 않는 습관을 보이고 있어요.',
      discomfort: '바른 자세도 오래 유지하면 피로가 쌓일 수 있으니 가끔 움직여 주세요.',
    ),
  };
}
