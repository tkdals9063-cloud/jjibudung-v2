import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

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
  // 끝에서 약 260px을 더 끌어야 100%가 된다.
  static const double _unlockDragDistance = 260;

  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _hasProfile = false;
  bool _isOpeningStretch = false;
  int _lastHapticStage = 0;
  double _pullProgress = 0;
  double? _lastPointerY;
  String _profileId = 'balanced';

  @override
  void initState() {
    super.initState();
    AppTabController.currentIndex.addListener(_handleTabChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    AppTabController.currentIndex.removeListener(_handleTabChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (AppTabController.currentIndex.value == 2) _loadProfile();
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
    setState(() => _isOpeningStretch = true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StretchRecommendationScreen(profileId: _profileId),
      ),
    );
    if (!mounted) return;
    setState(() {
      _isOpeningStretch = false;
      _pullProgress = 0;
      _lastHapticStage = 0;
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    _lastPointerY = event.position.dy;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isOpeningStretch ||
        !_scrollController.hasClients ||
        _lastPointerY == null) {
      return;
    }

    // 손가락이 위로 움직이면 양수, 아래로 움직이면 음수다.
    final dragAmount = _lastPointerY! - event.position.dy;
    _lastPointerY = event.position.dy;

    // 최하단에 도착하기 전이라면 충전을 취소한다.
    if (_scrollController.position.extentAfter > 1) {
      if (_pullProgress > 0) {
        setState(() {
          _pullProgress = 0;
          _lastHapticStage = 0;
        });
      }
      return;
    }

    if (dragAmount == 0) return;

    final nextProgress = (_pullProgress + dragAmount / _unlockDragDistance)
        .clamp(0.0, 1.0)
        .toDouble();
    final nextStage = (nextProgress * 4).floor();
    final shouldVibrate = nextStage > _lastHapticStage;

    setState(() {
      _pullProgress = nextProgress;
      _lastHapticStage = nextStage;
    });

    if (shouldVibrate) _playPullHaptic(nextStage);
  }

  Future<void> _playPullHaptic(int stage) async {
    final duration = switch (stage) {
      1 => 12,
      2 => 18,
      3 => 26,
      _ => 38,
    };
    final amplitude = switch (stage) {
      1 => 35,
      2 => 65,
      3 => 105,
      _ => 160,
    };

    if (await Vibration.hasVibrator()) {
      final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
      if (hasAmplitudeControl) {
        Vibration.vibrate(duration: duration, amplitude: amplitude);
      } else {
        Vibration.vibrate(duration: duration);
      }
      return;
    }

    // 진동 모터가 없는 기기에서는 시스템 햅틱으로 대체한다.
    switch (stage) {
      case 1:
        HapticFeedback.selectionClick();
        return;
      case 2:
        HapticFeedback.lightImpact();
        return;
      case 3:
        HapticFeedback.mediumImpact();
        return;
      case 4:
        HapticFeedback.heavyImpact();
        return;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _lastPointerY = null;
    if (_pullProgress >= 1) {
      _openStretch();
    } else if (_pullProgress > 0) {
      setState(() {
        _pullProgress = 0;
        _lastHapticStage = 0;
      });
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _lastPointerY = null;
    if (_pullProgress > 0) {
      setState(() {
        _pullProgress = 0;
        _lastHapticStage = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
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
      'forward' => const _ProfileInfo(
        code: 'FLS-A',
        firstEmoji: '🐢',
        secondEmoji: '🦊',
        name: '거북목 탐험가 + 앞기울임 여우',
        summary: '상체가 앞으로 쏠리고 골반이 앞쪽으로 기울기 쉬운 자세 경향이에요.',
        posture: '화면을 볼 때 턱과 어깨가 앞쪽으로 나오고, 허리가 과하게 꺾일 수 있어요.',
        habit: '목을 앞으로 빼고 앉거나, 한 자세로 화면을 오래 내려다보는 습관이 나타날 수 있어요.',
        discomfort: '오래 이어지면 목·어깨와 허리 주변이 뻐근하게 느껴질 수 있어요.',
      ),
      'slouch' => const _ProfileInfo(
        code: 'SSS-P',
        firstEmoji: '🐻',
        secondEmoji: '🦔',
        name: '굽은등 탐험가 + 말린 고슴도치',
        summary: '등과 골반이 뒤로 말리면서 몸통이 아래로 처지기 쉬운 자세 경향이에요.',
        posture: '등이 둥글어지고 가슴이 닫히며, 골반이 의자 앞쪽으로 미끄러질 수 있어요.',
        habit: '엉덩이를 의자 끝에 걸치거나 어깨를 안쪽으로 말고 앉는 습관이 나타날 수 있어요.',
        discomfort: '오래 이어지면 등·어깨와 골반 주변이 답답하거나 뻐근하게 느껴질 수 있어요.',
      ),
      _ => const _ProfileInfo(
        code: 'BPS-N',
        firstEmoji: '🐧',
        secondEmoji: '🦦',
        name: '균형 탐험가 + 중심 수달',
        summary: '상체와 골반의 중심을 비교적 안정적으로 유지하고 있는 자세 경향이에요.',
        posture: '머리·어깨·골반이 크게 한쪽으로 쏠리지 않고 편안한 균형을 유지해요.',
        habit: '자세를 자주 다시 맞추고, 몸에 힘을 과하게 주지 않는 습관을 보이고 있어요.',
        discomfort: '바른 자세도 오래 유지하면 피로가 쌓일 수 있으니 가끔 움직여 주세요.',
      ),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Listener(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '내 자세 친구들',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '측정 기록을 바탕으로 한 자세 경향이에요.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: '추천 스트레칭',
                      onPressed: _openStretch,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileHero(profile: profile),
                const SizedBox(height: 16),
                _InfoCard(
                  icon: Icons.accessibility_new_rounded,
                  title: '이 자세는 어떤 자세인가요?',
                  description: profile.posture,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.repeat_rounded,
                  title: '자주 보이는 습관',
                  description: profile.habit,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.favorite_outline_rounded,
                  title: '오래 지속할 때 느낄 수 있는 불편',
                  description: profile.discomfort,
                ),
                const SizedBox(height: 36),
                _PullToStretchIndicator(progress: _pullProgress),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PullToStretchIndicator extends StatelessWidget {
  final double progress;
  const _PullToStretchIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isReady = progress >= 1;
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: const Color(0xffE6DFFE),
                  color: const Color(0xff725AC1),
                ),
                Icon(
                  isReady
                      ? Icons.lock_open_rounded
                      : Icons.keyboard_double_arrow_down_rounded,
                  color: const Color(0xff725AC1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isReady ? '손을 떼면 추천 스트레칭을 보여드려요' : '끝까지 내린 뒤 더 당겨주세요',
            style: const TextStyle(
              color: Color(0xff725AC1),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
  final String posture;
  final String habit;
  final String discomfort;

  const _ProfileInfo({
    required this.code,
    required this.firstEmoji,
    required this.secondEmoji,
    required this.name,
    required this.summary,
    required this.posture,
    required this.habit,
    required this.discomfort,
  });
}
