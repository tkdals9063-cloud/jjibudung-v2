import 'package:flutter/material.dart';

import '../core/app_tab_controller.dart';
import '../services/storage_service.dart';
import 'preparation_screen.dart';
import 'stretch_recommendation_screen.dart';

class PostureProfileScreen extends StatefulWidget {
  const PostureProfileScreen({super.key});

  @override
  State<PostureProfileScreen> createState() => _PostureProfileScreenState();
}

class _PostureProfileScreenState extends State<PostureProfileScreen> {
  bool _isLoading = true;
  bool _hasProfile = false;
  bool _isOpeningStretch = false;
  String _profileId = 'balanced';

  @override
  void initState() {
    super.initState();
    AppTabController.currentIndex.addListener(_handleTabChanged);
    _loadProfile();
  }

  void _handleTabChanged() {
    if (AppTabController.currentIndex.value == 2) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    AppTabController.currentIndex.removeListener(_handleTabChanged);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final hasProfile = await StorageService.loadHasInitialPostureProfile();
    final profileId = await StorageService.loadPostureProfileId();

    if (!mounted) return;
    setState(() {
      _hasProfile = hasProfile;
      _profileId = profileId;
      _isLoading = false;
    });
  }

  Future<void> _openStretch() async {
    if (_isOpeningStretch) return;
    _isOpeningStretch = true;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StretchRecommendationScreen(profileId: _profileId),
      ),
    );

    _isOpeningStretch = false;
  }

  bool _handleScrollEnd(ScrollEndNotification notification) {
    final position = notification.metrics;
    final reachedBottom = position.pixels > 0 && position.extentAfter <= 0;

    // 끝까지 내린 뒤 손을 뗐을 때만 추천 화면을 연다.
    if (reachedBottom) _openStretch();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasProfile) {
      return _ProfileRequiredView(
        onStart: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PreparationScreen()),
          );
          _loadProfile();
        },
      );
    }

    final profile = switch (_profileId) {
      'forward' => _ProfileInfo(
        code: 'FLS-A',
        firstEmoji: '🐢',
        secondEmoji: '🦊',
        name: '거북목 탐험가 + 앞기울임 여우',
        summary: '화면을 보거나 오래 앉아 있을 때 상체가 앞으로 쏠리기 쉬운 자세 친구예요.',
        tendencyTitle: '앞으로 쏠림 · 골반 앞기울임 경향',
        tendency: '턱과 어깨가 앞쪽으로 나오고 허리가 과하게 꺾이지 않도록 살펴보는 것이 좋아요.',
        risk: '같은 자세가 오래 이어지면 목·어깨와 허리 주변이 뻐근하게 느껴질 수 있어요.',
        tip: '턱을 살짝 당기고, 어깨 힘을 뺀 뒤 발바닥을 바닥에 붙여보세요.',
      ),
      'slouch' => _ProfileInfo(
        code: 'SSS-P',
        firstEmoji: '🐻',
        secondEmoji: '🦔',
        name: '꾸벅 곰 + 말린 고슴도치',
        summary: '앉아 있을수록 등이 둥글어지고 몸통이 아래로 말리기 쉬운 자세 친구예요.',
        tendencyTitle: '등 말림 · 골반 뒤기울임 경향',
        tendency: '가슴이 닫히고 골반이 뒤로 말리기 쉬워 등과 엉덩이가 답답해질 수 있어요.',
        risk: '같은 자세가 오래 이어지면 등·어깨와 골반 주변이 뻐근하게 느껴질 수 있어요.',
        tip: '엉덩이를 의자 깊숙이 넣고 가슴을 가볍게 열어보세요.',
      ),
      _ => _ProfileInfo(
        code: 'BPS-N',
        firstEmoji: '🐧',
        secondEmoji: '🦦',
        name: '바른자세 펭귄 + 중심 수달',
        summary: '균형 잡힌 기준 자세를 잘 유지하고 있는 든든한 자세 친구들이에요.',
        tendencyTitle: '균형 잡힌 자세 유지 경향',
        tendency: '상체와 골반의 중심이 비교적 안정적이에요. 지금의 편안한 균형을 이어가면 돼요.',
        risk: '바른 자세도 오래 유지하면 피로가 쌓일 수 있으니, 가끔 움직여 주세요.',
        tip: '30분마다 한 번씩 목과 어깨를 가볍게 움직여 좋은 흐름을 이어가세요.',
      ),
    };
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: NotificationListener<ScrollEndNotification>(
          onNotification: _handleScrollEnd,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '내 자세 친구들',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '현재 측정 기록을 바탕으로 한 자세 경향이에요.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                _ProfileHero(profile: profile),
                const SizedBox(height: 16),
                _InfoCard(
                  icon: Icons.person_outline_rounded,
                  title: profile.tendencyTitle,
                  description: profile.tendency,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.favorite_outline_rounded,
                  title: '오래 지속되면',
                  description: profile.risk,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.lightbulb_outline_rounded,
                  title: '오늘의 작은 팁',
                  description: profile.tip,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _openStretch,
                    icon: const Icon(Icons.self_improvement_rounded),
                    label: const Text('내게 맞는 스트레칭 추천'),
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xff725AC1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_double_arrow_down_rounded,
                        color: Color(0xff725AC1),
                      ),
                      SizedBox(height: 8),
                      Opacity(
                        opacity: 0.62,
                        child: Text(
                          '끝까지 내린 뒤 손을 떼면\n추천 스트레칭으로 이동해요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xff725AC1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRequiredView extends StatelessWidget {
  final VoidCallback onStart;

  const _ProfileRequiredView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐣', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              '내 자세 친구를 만나볼까요?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '홈에서 START를 누르고 5초 기준 자세 측정을 하면\n나만의 자세 친구가 나타나요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onStart, child: const Text('기준 자세 측정하기')),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final _ProfileInfo profile;
  const _ProfileHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xffF5F1FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            profile.code,
            style: const TextStyle(
              color: Color(0xff725AC1),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${profile.firstEmoji}  +  ${profile.secondEmoji}',
            style: const TextStyle(fontSize: 54),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            profile.summary,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffE6DFFE)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff725AC1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfo {
  final String code;
  final String firstEmoji;
  final String secondEmoji;
  final String name;
  final String summary;
  final String tendencyTitle;
  final String tendency;
  final String risk;
  final String tip;

  const _ProfileInfo({
    required this.code,
    required this.firstEmoji,
    required this.secondEmoji,
    required this.name,
    required this.summary,
    required this.tendencyTitle,
    required this.tendency,
    required this.risk,
    required this.tip,
  });
}
