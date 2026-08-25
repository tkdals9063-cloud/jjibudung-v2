import 'dart:math';

import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../data/quotes.dart';
import '../core/app_tab_controller.dart';
import '../services/storage_service.dart';
import '../widgets/posture_profile_summary_card.dart';
import '../widgets/posture_profile_unlock_card.dart';
import '../widgets/study_dashboard_card.dart';
import '../widgets/summary_card.dart';
import 'preparation_screen.dart';
import 'work_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const List<QuotesData> quotes = [
    QuotesData(quote: '성공은 매일 반복한 작은 노력들의 합이다.', author: '로버트 콜리어'),
    QuotesData(quote: '우리는 반복하는 행동의 결과물이다.', author: '아리스토텔레스'),
    QuotesData(quote: '천재는 1%의 영감과 99%의 노력이다.', author: '토머스 에디슨'),
    QuotesData(quote: '미래를 예측하는 가장 좋은 방법은 미래를 만드는 것이다.', author: '피터 드러커'),
    QuotesData(quote: '오늘의 작은 성장이 내일의 큰 변화를 만든다.', author: '제임스 클리어'),
  ];

  int _todayStudyTime = 0;
  int _todayGoodPostureTime = 0;
  int _point = 0;
  List<bool> _weekUsage = List<bool>.filled(7, false);
  bool _hasPostureProfile = false;
  String _postureProfileId = 'balanced';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final today = await StorageService.loadTodayStudyTime();
    final good = await StorageService.loadTodayGoodPostureTime();
    final point = await StorageService.loadPoint();
    final weekUsage = await StorageService.loadCurrentWeekUsage();
    final hasPostureProfile =
        await StorageService.loadHasInitialPostureProfile();
    final postureProfileId = await StorageService.loadPostureProfileId();

    if (!mounted) return;

    setState(() {
      _todayStudyTime = today;
      _todayGoodPostureTime = good;
      _point = point;
      _weekUsage = weekUsage;
      _hasPostureProfile = hasPostureProfile;
      _postureProfileId = postureProfileId;
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '좋은 아침입니다 ☀️';
    if (hour < 18) return '좋은 오후입니다 🌤';
    return '좋은 저녁입니다 🌙';
  }

  String _levelName() {
    if (_point >= 1500) return 'Lv.5 마스터';
    if (_point >= 700) return 'Lv.4 고인물';
    if (_point >= 300) return 'Lv.3 중수';
    if (_point >= 100) return 'Lv.2 초보자';
    return 'Lv.1 슬라임';
  }

  Future<void> _openPreparation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PreparationScreen()),
    );

    if (mounted) _loadData();
  }

  Future<void> _startTimeOnly() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkScreen()),
    );

    if (mounted) _loadData();
  }

  void _openStatistics() {
    AppTabController.currentIndex.value = 1;
  }

  void _openStore() {
    AppTabController.currentIndex.value = 3;
  }

  void _showChairComingSoon() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xffF5F1FF),
                  child: Icon(
                    Icons.chair_alt_rounded,
                    size: 36,
                    color: Color(0xff725AC1),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '찌뿌둥 체어',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '바른 자세 유지율, 좌우 균형, 자세 분석은\n찌뿌둥 체어 연동 후 확인할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffF5F1FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.construction_rounded,
                        color: Color(0xff725AC1),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '현재 찌뿌둥 체어를 준비하고 있어요.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showStartChoices() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _hasPostureProfile ? '무엇을 할까요?' : '찌뿌둥 시작하기',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '휴대폰만 사용하는 동안에는 사용 시간을 기록해요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                _StartChoiceButton(
                  icon: Icons.accessibility_new_rounded,
                  title: _hasPostureProfile ? '기준 각도 다시 측정하기' : '기준 각도 측정하기',
                  subtitle: '자세 친구와 펫을 새로 확인해요.',
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openPreparation();
                  },
                ),
                const SizedBox(height: 12),
                _StartChoiceButton(
                  icon: Icons.timer_outlined,
                  title: '시간 기록 시작하기',
                  subtitle: '자세 측정 없이 바로 시간을 기록해요.',
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _startTimeOnly();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final quote = quotes[Random().nextInt(quotes.length)];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 20,
                child: Marquee(
                  text: '${quote.quote} - ${quote.author}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  blankSpace: 80,
                  velocity: 28,
                  pauseAfterRound: const Duration(seconds: 1),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _greeting(),
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                '찌뿌둥',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff725AC1),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SummaryCard(
                    icon: Icons.eco,
                    iconColor: Colors.greenAccent,
                    title: '현재 레벨',
                    value: 'Lv.${_levelName().substring(3, 4)}',
                    subtitle: _levelName().substring(5),
                  ),
                  const SizedBox(width: 12),
                  SummaryCard(
                    icon: Icons.lock_outline_rounded,
                    iconColor: Colors.deepPurpleAccent,
                    title: '자세 분석',
                    value: '연동 전',
                    subtitle: '의자 필요',
                  ),
                  const SizedBox(width: 12),
                  SummaryCard(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    title: '포인트',
                    value: '$_point',
                    subtitle: '누적 포인트',
                    onTap: _openStore,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              StudyDashboardCard(
                goodPostureTime: _todayGoodPostureTime,
                totalMeasureTime: _todayStudyTime,
                weekUsage: _weekUsage,
                onPressed: _showStartChoices,
                onStatisticsPressed: _openStatistics,
                onChairPressed: _showChairComingSoon,
              ),
              const SizedBox(height: 16),
              if (_hasPostureProfile)
                PostureProfileSummaryCard(profileId: _postureProfileId)
              else
                PostureProfileUnlockCard(onPressed: _openPreparation),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartChoiceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _StartChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF5F1FF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xff725AC1),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
