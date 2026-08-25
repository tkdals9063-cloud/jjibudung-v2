import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class StretchRecommendationScreen extends StatefulWidget {
  final String profileId;

  const StretchRecommendationScreen({super.key, this.profileId = 'balanced'});

  @override
  State<StretchRecommendationScreen> createState() =>
      _StretchRecommendationScreenState();
}

class _StretchRecommendationScreenState
    extends State<StretchRecommendationScreen> {
  int? _completedToday;

  StretchRoutine get _routine => _routineFor(widget.profileId);

  @override
  void initState() {
    super.initState();
    _loadCompletedCount();
  }

  Future<void> _loadCompletedCount() async {
    final count = await StorageService.loadTodayStretchRoutineCount();
    if (mounted) setState(() => _completedToday = count);
  }

  Future<void> _startRoutine() async {
    if ((_completedToday ?? 0) >= StorageService.phoneDailyStretchLimit) {
      _showChairComingSoon();
      return;
    }

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StretchRoutineScreen(routine: _routine),
      ),
    );

    if (completed == true) _loadCompletedCount();
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
                const Icon(
                  Icons.chair_alt_rounded,
                  size: 52,
                  color: Color(0xff725AC1),
                ),
                const SizedBox(height: 14),
                const Text(
                  '오늘의 휴대폰 루틴을 완료했어요!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '휴대폰 단독 모드에서는 하루 1회까지 제공해요.\n맞춤형 추가 루틴은 찌뿌둥 체어와 함께 준비 중이에요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
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

  @override
  Widget build(BuildContext context) {
    final completedToday = _completedToday;
    final isLimitReached =
        (completedToday ?? 0) >= StorageService.phoneDailyStretchLimit;

    return Scaffold(
      appBar: AppBar(title: Text(_routine.title)),
      body: completedToday == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xffF5F1FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _routine.emoji,
                            style: const TextStyle(fontSize: 50),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _routine.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '오늘의 루틴',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._routine.moves.asMap().entries.map((entry) {
                      final move = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            CircleAvatar(child: Text('${entry.key + 1}')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                move.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${move.sets}세트',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Spacer(),
                    Text(
                      '오늘 완료 $completedToday / ${StorageService.phoneDailyStretchLimit}회 · 완료 보상 +${StorageService.stretchRoutinePoint}P',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isLimitReached ? Colors.orange : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _startRoutine,
                        icon: Icon(
                          isLimitReached
                              ? Icons.lock_outline
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          isLimitReached ? '추가 루틴은 체어 연동 후' : '스트레칭 시작',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class StretchRoutineScreen extends StatefulWidget {
  final StretchRoutine routine;

  const StretchRoutineScreen({super.key, required this.routine});

  @override
  State<StretchRoutineScreen> createState() => _StretchRoutineScreenState();
}

class _StretchRoutineScreenState extends State<StretchRoutineScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _guideController;
  int _moveIndex = 0;
  int _currentSet = 1;
  int _secondsLeft = 0;
  int _countdown = 0;
  int _restSeconds = 0;
  bool _isRunning = false;
  bool _isResting = false;
  bool _isCompleted = false;

  StretchMove get _move => widget.routine.moves[_moveIndex];

  @override
  void initState() {
    super.initState();
    _secondsLeft = _move.seconds;
    _guideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  Future<void> _startSet() async {
    if (_isRunning || _isResting || _isCompleted) return;

    for (var value = 3; value >= 1; value--) {
      if (!mounted) return;
      setState(() => _countdown = value);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;

    setState(() {
      _countdown = 0;
      _secondsLeft = _move.seconds;
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _isRunning = false;
        });
        _finishSet();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _finishSet() async {
    if (_currentSet < _move.sets) {
      setState(() {
        _isResting = true;
        _restSeconds = 10;
      });

      for (var second = 10; second >= 1; second--) {
        if (!mounted) return;
        setState(() => _restSeconds = second);
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (!mounted) return;

      setState(() {
        _currentSet++;
        _isResting = false;
      });
      _startSet();
      return;
    }

    if (_moveIndex < widget.routine.moves.length - 1) {
      setState(() {
        _moveIndex++;
        _currentSet = 1;
        _secondsLeft = _move.seconds;
      });
      return;
    }

    final saved = await StorageService.completePhoneStretchRoutine();
    if (!mounted) return;
    setState(() => _isCompleted = saved);
  }

  Future<void> _attemptExit() async {
    if (_isCompleted) {
      Navigator.pop(context, true);
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('루틴을 나갈까요?'),
        content: const Text('완료 전에는 스트레칭 포인트가 지급되지 않아요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속하기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context, false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _guideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return _buildCompletion(context);

    final progress = _isRunning ? 1 - (_secondsLeft / _move.seconds) : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _attemptExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _attemptExit,
          ),
          title: Text('${_moveIndex + 1} / ${widget.routine.moves.length}'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _move.target,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff725AC1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _move.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _move.guide,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _AnimatedStretchGuide(
                    controller: _guideController,
                    target: _move.target,
                    active: _isRunning,
                  ),
                ),
                if (_countdown > 0)
                  Text(
                    '$_countdown',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff725AC1),
                    ),
                  )
                else if (_isResting)
                  Column(
                    children: [
                      const Text(
                        '잠깐 쉬어요',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$_restSeconds초',
                        style: const TextStyle(
                          fontSize: 34,
                          color: Color(0xff725AC1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        '$_currentSet / ${_move.sets} 세트',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 112,
                        height: 112,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 112,
                              height: 112,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 9,
                              ),
                            ),
                            Text(
                              _isRunning
                                  ? '$_secondsLeft초'
                                  : '${_move.seconds}초',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 22),
                if (!_isRunning && !_isResting && _countdown == 0)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _startSet,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(_moveIndex == 0 ? '스트레칭 시작' : '다음 스트레칭 시작'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletion(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('루틴 완료'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 88,
                color: Colors.amber,
              ),
              const SizedBox(height: 20),
              const Text(
                '오늘의 스트레칭 완료!',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '+${StorageService.stretchRoutinePoint}P를 받았어요',
                style: const TextStyle(
                  fontSize: 19,
                  color: Color(0xff725AC1),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedStretchGuide extends StatelessWidget {
  final AnimationController controller;
  final String target;
  final bool active;

  const _AnimatedStretchGuide({
    required this.controller,
    required this.target,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final movement = sin(controller.value * pi * 2) * (active ? 10 : 3);
        return Center(
          child: Transform.translate(
            offset: Offset(0, movement),
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xffF5F1FF),
                borderRadius: BorderRadius.circular(48),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.accessibility_new_rounded,
                    size: 88,
                    color: Color(0xff725AC1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$target 집중',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff725AC1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

StretchRoutine _routineFor(String profileId) {
  return switch (profileId) {
    'forward' => const StretchRoutine(
      title: 'FLS-A 맞춤 스트레칭',
      emoji: '🐢🦊',
      message: '거북목 탐험가를 위한\n서서 하는 2분 자세 리셋이에요.',
      moves: [
        StretchMove('목 앞쪽 이완', '목', '턱을 살짝 당긴 뒤, 시선만 천천히 위로 올려주세요.', 20, 2),
        StretchMove('가슴 열기', '가슴·어깨', '양손을 등 뒤에서 잡고 어깨를 뒤로 편하게 열어주세요.', 25, 2),
      ],
    ),
    'slouch' => const StretchRoutine(
      title: 'SSS-P 맞춤 스트레칭',
      emoji: '🐻🦔',
      message: '꾸벅 곰을 위한\n등을 펴는 2분 리셋 루틴이에요.',
      moves: [
        StretchMove('서서 가슴 펴기', '가슴·등', '두 손을 뒤로 보내고 가슴을 가볍게 열어주세요.', 25, 2),
        StretchMove('등 길게 늘리기', '등', '양손을 앞으로 뻗으며 등을 길게 늘려주세요.', 25, 2),
      ],
    ),
    _ => const StretchRoutine(
      title: 'BPS-N 맞춤 스트레칭',
      emoji: '🐧🦦',
      message: '바른 흐름을 지키는\n가벼운 2분 유지 루틴이에요.',
      moves: [
        StretchMove('목 옆 늘리기', '목', '고개를 한쪽으로 천천히 기울여 목 옆을 편안하게 늘려주세요.', 20, 2),
        StretchMove('어깨 뒤로 돌리기', '어깨', '어깨를 크게 뒤로 천천히 돌려 긴장을 풀어주세요.', 25, 2),
      ],
    ),
  };
}

class StretchRoutine {
  final String title;
  final String emoji;
  final String message;
  final List<StretchMove> moves;

  const StretchRoutine({
    required this.title,
    required this.emoji,
    required this.message,
    required this.moves,
  });
}

class StretchMove {
  final String title;
  final String target;
  final String guide;
  final int seconds;
  final int sets;

  const StretchMove(
    this.title,
    this.target,
    this.guide,
    this.seconds,
    this.sets,
  );
}
