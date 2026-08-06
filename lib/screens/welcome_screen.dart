import 'dart:math';

import 'package:flutter/material.dart';

import 'preparation_screen.dart';
import '../data/quotes.dart';
import '../services/storage_service.dart';
import 'played_screen.dart';
import 'package:marquee/marquee.dart';
import '../widgets/summary_card.dart';
import '../widgets/study_dashboard_card.dart';
import '../widgets/posture_profile_summary_card.dart';
import '../widgets/posture_profile_unlock_card.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const List<QuotesData> quotes = [
    QuotesData(quote: "성공은 매일 반복한 작은 노력들의 합이다.", author: "로버트 콜리어"),
    QuotesData(quote: "우리는 반복하는 행동의 결과물이다.", author: "아리스토텔레스"),
    QuotesData(quote: "천재는 1%의 영감과 99%의 노력이다.", author: "토머스 에디슨"),
    QuotesData(quote: "미래를 예측하는 가장 좋은 방법은 미래를 만드는 것이다.", author: "피터 드러커"),
    QuotesData(quote: "오늘의 작은 성장이 내일의 큰 변화를 만든다.", author: "제임스 클리어"),
  ];
  int _todayStudyTime = 0;
  int _todayGoodPostureTime = 0;

  int _point = 0;
  int _streak = 0;
  double _postureRate = 100.0;

  List<bool> _weekUsage = List<bool>.filled(7, false);

  bool _hasPostureProfile = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final today = await StorageService.loadTodayStudyTime();
    final good = await StorageService.loadTodayGoodPostureTime();
    final point = await StorageService.loadPoint();
    final streak = await StorageService.loadStreak();
    final weekUsage = await StorageService.loadCurrentWeekUsage();
    final hasPostureProfile =
        await StorageService.loadHasInitialPostureProfile();

    if (!mounted) return;

    setState(() {
      _todayStudyTime = today;
      _todayGoodPostureTime = good;
      _point = point;
      _streak = streak;
      _weekUsage = weekUsage;
      _hasPostureProfile = hasPostureProfile;
      _postureRate = today == 0 ? 100 : (good / today) * 100;
    });
  }

  String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "좋은 아침입니다 ☀️";
    } else if (hour < 18) {
      return "좋은 오후입니다 🌤";
    } else {
      return "좋은 저녁입니다 🌙";
    }
  }

  String getLevel() {
    if (_point >= 1500) {
      return "Lv.5 마스터";
    } else if (_point >= 700) {
      return "Lv.4 고인물";
    } else if (_point >= 300) {
      return "Lv.3 중수";
    } else if (_point >= 100) {
      return "Lv.2 초보자";
    } else {
      return "Lv.1 슬라임";
    }
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
                  text: "${quote.quote} - ${quote.author}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  blankSpace: 80,
                  velocity: 28,
                  pauseAfterRound: const Duration(seconds: 1),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                greeting(),
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "찌뿌둥",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff725AC1),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.analytics_outlined, size: 30),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlayedScreen()),
                      );
                    },
                  ),
                ],
              ),

              Row(
                children: [
                  SummaryCard(
                    icon: Icons.eco,
                    iconColor: Colors.greenAccent,
                    title: "현재 레벨",
                    value: "Lv.${getLevel().substring(3, 4)}",
                    subtitle: getLevel().substring(5),
                  ),

                  const SizedBox(width: 12),

                  SummaryCard(
                    icon: Icons.sentiment_satisfied_alt,
                    iconColor: Colors.lightBlueAccent,
                    title: "바른 자세",
                    value: "${_postureRate.toStringAsFixed(1)}%",
                    subtitle: "격주 평균",
                  ),

                  const SizedBox(width: 12),

                  SummaryCard(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    title: "포인트",
                    value: "$_point",
                    subtitle: "누적 포인트",
                  ),
                ],
              ),

              StudyDashboardCard(
                goodPostureTime: _todayGoodPostureTime,
                totalMeasureTime: _todayStudyTime,
                weekUsage: _weekUsage,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PreparationScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              if (_hasPostureProfile)
                const PostureProfileSummaryCard()
              else
                PostureProfileUnlockCard(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PreparationScreen(),
                      ),
                    );
                    if (mounted) _loadData();
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
