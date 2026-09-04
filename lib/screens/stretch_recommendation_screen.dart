import 'dart:async';
import 'dart:math' as math;

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
  late CorrectiveRoutine _routine;

  @override
  void initState() {
    super.initState();
    _routine = _routineFor(widget.profileId);
    _loadCompletedCount();
  }

  Future<void> _loadCompletedCount() async {
    final count = await StorageService.loadTodayStretchRoutineCount();
    if (mounted) {
      setState(() => _completedToday = count);
    }
  }

  Future<void> _startRoutine() async {
    if ((_completedToday ?? 0) >= StorageService.phoneDailyStretchLimit) {
      _showChairComingSoon();
      return;
    }

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CorrectiveRoutineScreen(routine: _routine),
      ),
    );

    if (completed == true) {
      _loadCompletedCount();
    }
  }

  void _showChairComingSoon() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
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
                '휴대폰 단독 모드에서는 하루 1회까지 제공해요.\n'
                '맞춤형 추가 루틴은 찌뿌둥 체어와 함께 준비 중이에요.',
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
      ),
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
              child: SingleChildScrollView(
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
                            style: const TextStyle(fontSize: 48),
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
                    const SizedBox(height: 22),
                    const Text(
                      '오늘의 랜덤 교정 루틴',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '긴장된 부위를 먼저 풀고, 자세를 받쳐 줄 근육을 깨워요.',
                      style: TextStyle(color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    _RoutinePart(
                      title: '1. 이완 파트',
                      caption: '긴장된 부위를 부드럽게 늘려요',
                      color: const Color(0xff805EC5),
                      children: [
                        for (final entry in _routine.pairs.asMap().entries)
                          _RoutineMoveCard(
                            number: entry.key + 1,
                            move: entry.value.release,
                            onSwap: () => _swapMove(entry.key, MoveRole.release),
                            onInfo: () => _showRecommendationReason(entry.value),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _RoutinePart(
                      title: '2. 수축 파트',
                      caption: '자세를 지지할 근육에 가볍게 힘을 주세요',
                      color: const Color(0xffD96B42),
                      children: [
                        for (final entry in _routine.pairs.asMap().entries)
                          _RoutineMoveCard(
                            number: entry.key + 1,
                            move: entry.value.activate,
                            onSwap: () => _swapMove(entry.key, MoveRole.activate),
                            onInfo: () => _showRecommendationReason(entry.value),
                          ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF8E8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Color(0xffA66B00)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '통증, 저림, 어지럼이 느껴지면 바로 멈추세요. '
                              '이 루틴은 진단이나 치료를 대신하지 않아요.',
                              style: TextStyle(fontSize: 13, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '오늘 완료 $completedToday / '
                      '${StorageService.phoneDailyStretchLimit}회 · '
                      '완료 보상 +${StorageService.stretchRoutinePoint}P',
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
                          isLimitReached ? '추가 루틴은 체어 연동 후' : '약 4분 루틴 시작',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _swapMove(int pairIndex, MoveRole role) async {
    final currentPair = _routine.pairs[pairIndex];
    final currentMove = role == MoveRole.release
        ? currentPair.release
        : currentPair.activate;
    final selected = await Navigator.push<CorrectiveMove>(
      context,
      MaterialPageRoute(
        builder: (_) => StretchMovePickerScreen(
          profileId: widget.profileId,
          role: role,
          currentMove: currentMove,
        ),
      ),
    );

    if (selected == null || !mounted) return;

    final replacement = currentPair.copyWith(
      release: role == MoveRole.release ? selected : null,
      activate: role == MoveRole.activate ? selected : null,
    );
    final pairs = [..._routine.pairs]..[pairIndex] = replacement;
    setState(() => _routine = _routine.copyWith(pairs: pairs));
  }

  void _showRecommendationReason(CorrectivePair pair) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.thumb_up_alt_rounded, color: Color(0xff725AC1)),
                  SizedBox(width: 8),
                  Text(
                    '왜 이 조합을 추천하나요?',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(pair.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(pair.recommendationReason, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 12),
              const Text(
                '측정으로 파악한 자세 경향을 바탕으로 우선순위를 정한 안내예요. 통증이 있으면 진행하지 마세요.',
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutinePart extends StatelessWidget {
  final String title;
  final String caption;
  final Color color;
  final List<Widget> children;

  const _RoutinePart({
    required this.title,
    required this.caption,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 3),
          Text(caption, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _RoutineMoveCard extends StatelessWidget {
  final int number;
  final CorrectiveMove move;
  final VoidCallback onSwap;
  final VoidCallback onInfo;

  const _RoutineMoveCard({
    required this.number,
    required this.move,
    required this.onSwap,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isRelease = move.role == MoveRole.release;
    final color = isRelease ? const Color(0xff805EC5) : const Color(0xffD96B42);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.13),
            foregroundColor: color,
            child: Text('$number', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(move.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${move.target} · ${move.sets}세트', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            tooltip: '추천 이유',
            onPressed: onInfo,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.thumb_up_alt_outlined, size: 19, color: color),
          ),
          IconButton(
            tooltip: '다른 동작 고르기',
            onPressed: onSwap,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.sync_rounded, size: 21, color: color),
          ),
        ],
      ),
    );
  }
}

class StretchMovePickerScreen extends StatelessWidget {
  final String profileId;
  final MoveRole role;
  final CorrectiveMove currentMove;

  const StretchMovePickerScreen({
    super.key,
    required this.profileId,
    required this.role,
    required this.currentMove,
  });

  @override
  Widget build(BuildContext context) {
    final options = _stretchMoveOptions(role);
    final partTitle = role == MoveRole.release ? '이완 동작' : '수축 동작';

    return Scaffold(
      appBar: AppBar(title: const Text('스트레칭 고르기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text('$partTitle 바꾸기', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            '오래 앉아 있는 날에 도움이 되는 동작이에요. 현재 자세 경향에 맞지 않는 항목은 회색으로 표시돼요.',
            style: TextStyle(color: Colors.grey, height: 1.45),
          ),
          const SizedBox(height: 18),
          ...options.map((option) {
            final isCurrent = option.move.title == currentMove.title;
            final isBlocked = option.blockedProfileIds.contains(profileId);
            return _PickerMoveCard(
              option: option,
              isCurrent: isCurrent,
              isBlocked: isBlocked,
              onTap: () {
                if (isBlocked) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text('현재 자세 경향에는 비추천 스트레칭이에요!')));
                } else if (!isCurrent) {
                  Navigator.pop(context, option.move);
                }
              },
            );
          }),
        ],
      ),
    );
  }
}

class _PickerMoveCard extends StatelessWidget {
  final _MoveOption option;
  final bool isCurrent;
  final bool isBlocked;
  final VoidCallback onTap;

  const _PickerMoveCard({
    required this.option,
    required this.isCurrent,
    required this.isBlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isBlocked ? const Color(0xffF1F1F3) : Colors.white;
    final textColor = isBlocked ? Colors.grey.shade600 : const Color(0xff24232A);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: background,
      elevation: isBlocked ? 0 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isBlocked ? Icons.lock_outline_rounded : Icons.self_improvement_rounded, color: isBlocked ? Colors.grey : const Color(0xff725AC1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(option.move.title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                        _PickerLabel(
                          text: isCurrent ? '현재 선택됨' : isBlocked ? '비추천' : '추천',
                          color: isBlocked ? Colors.grey.shade600 : isCurrent ? const Color(0xff725AC1) : const Color(0xff3C8E6B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(option.move.target, style: TextStyle(color: textColor)),
                    const SizedBox(height: 6),
                    Text(option.reason, style: TextStyle(fontSize: 12, color: isBlocked ? Colors.grey : Colors.grey.shade700, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _PickerLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class CorrectiveRoutineScreen extends StatefulWidget {
  final CorrectiveRoutine routine;

  const CorrectiveRoutineScreen({super.key, required this.routine});

  @override
  State<CorrectiveRoutineScreen> createState() =>
      _CorrectiveRoutineScreenState();
}

class _CorrectiveRoutineScreenState extends State<CorrectiveRoutineScreen>
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

  CorrectiveMove get _move => widget.routine.moves[_moveIndex];

  @override
  void initState() {
    super.initState();
    _secondsLeft = _move.seconds;
    _guideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
    if (leave == true && mounted) {
      Navigator.pop(context, false);
    }
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
    final isRelease = _move.role == MoveRole.release;

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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isRelease
                        ? const Color(0xffF1EBFF)
                        : const Color(0xffFFF0E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRelease ? '1단계 · 답답한 부위 이완' : '2단계 · 지지 근육 활성화',
                    style: TextStyle(
                      color: isRelease
                          ? const Color(0xff805EC5)
                          : const Color(0xffC55A34),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  _move.target,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff725AC1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _move.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _move.guide,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.45),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _SmoothExerciseGuide(
                    controller: _guideController,
                    move: _move,
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
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 106,
                        height: 106,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 106,
                              height: 106,
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
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                if (!_isRunning && !_isResting && _countdown == 0)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _startSet,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(_moveIndex == 0 ? '3초 후 시작' : '다음 운동 시작'),
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
                '오늘의 교정 루틴 완료!',
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

String _guideAssetPath(FigureAnimation animation) {
  return switch (animation) {
    FigureAnimation.neckRelease => 'assets/stretch/neck_release_v1.png',
    FigureAnimation.chinTuck => 'assets/stretch/chin_tuck_v1.png',
    FigureAnimation.chestOpen => 'assets/stretch/chest_open_v1.png',
    FigureAnimation.scapularSet => 'assets/stretch/scapular_set_v1.png',
    FigureAnimation.upperBackReach => 'assets/stretch/upper_back_reach_v1.png',
    FigureAnimation.wallY => 'assets/stretch/wall_y_v1.png',
    FigureAnimation.shoulderRoll => 'assets/stretch/shoulder_roll_v1.png',
    FigureAnimation.hipFlexor => 'assets/stretch/rectus_femoris_stretch_v1.png',
    FigureAnimation.gluteSet => 'assets/stretch/glute_extension_v1.png',
  };
}

class _SmoothExerciseGuide extends StatelessWidget {
  final AnimationController controller;
  final CorrectiveMove move;

  const _SmoothExerciseGuide({required this.controller, required this.move});

  @override
  Widget build(BuildContext context) {
    if (move.animation == FigureAnimation.hipFlexor) {
      return const _FrameSequenceGuide();
    }

    final assetPath = _guideAssetPath(move.animation);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff171923),
        borderRadius: BorderRadius.circular(28),
      ),
      child: AnimatedBuilder(
        animation: controller,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        builder: (context, child) {
          final pulse = math.sin(controller.value * math.pi);
          final isShoulderRoll = move.animation == FigureAnimation.shoulderRoll;
          final isHipMovement =
              move.animation == FigureAnimation.hipFlexor ||
              move.animation == FigureAnimation.gluteSet;

          return Transform.translate(
            offset: Offset(0, -4 * pulse),
            child: Transform.rotate(
              angle: isShoulderRoll
                  ? 0.018 * math.sin(controller.value * math.pi * 2)
                  : (isHipMovement ? -0.010 * pulse : 0),
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scale: 1 + 0.014 * pulse,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FrameSequenceGuide extends StatefulWidget {
  const _FrameSequenceGuide();

  @override
  State<_FrameSequenceGuide> createState() => _FrameSequenceGuideState();
}

class _FrameSequenceGuideState extends State<_FrameSequenceGuide> {
  static const _frameCount = 24;
  static const _frameDuration = Duration(milliseconds: 250);
  Timer? _timer;
  var _frameIndex = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_frameDuration, (_) {
      if (!mounted) return;
      setState(() => _frameIndex = _frameIndex % _frameCount + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frameName = _frameIndex.toString().padLeft(2, '0');
    final assetPath =
        'assets/exercise/bps_rectus_femoris_female_penguin_v2/frame_$frameName.png';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff171923),
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 90),
          child: Image.asset(
            assetPath,
            key: ValueKey(_frameIndex),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _HipFlexorAnatomyPainter extends CustomPainter {
  final double phase;

  const _HipFlexorAnatomyPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 280, size.height / 320);
    final origin = Offset(
      (size.width - 280 * scale) / 2,
      (size.height - 320 * scale) / 2,
    );
    canvas
      ..save()
      ..translate(origin.dx, origin.dy)
      ..scale(scale);

    final body = Paint()..color = const Color(0xffE8EAF0);
    final edge = Paint()
      ..color = const Color(0xff73798A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeJoin = StrokeJoin.round;
    final shorts = Paint()..color = const Color(0xff404553);
    final lavender = Paint()
      ..color = const Color(0xff9A7AD3).withValues(alpha: 0.62 + phase * 0.20);
    final window = Paint()..color = Colors.white.withValues(alpha: 0.45);
    final cue = Paint()
      ..color = const Color(0xff9A7AD3).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    const rearHip = Offset(126, 181);
    final rearKnee = Offset(74, 245 - phase * 3);
    const rearAnkle = Offset(28, 298);
    const frontHip = Offset(155, 181);
    const frontKnee = Offset(211, 221);
    const frontAnkle = Offset(216, 298);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(140, 303), width: 214, height: 13),
      Paint()..color = const Color(0xffBAC0CF).withValues(alpha: 0.25),
    );
    _limb(canvas, rearHip, rearKnee, 27, body, edge);
    _limb(canvas, rearKnee, rearAnkle, 23, body, edge);
    _limb(canvas, frontHip, frontKnee, 29, body, edge);
    _limb(canvas, frontKnee, frontAnkle, 24, body, edge);

    final torso = Path()
      ..moveTo(112, 95)
      ..quadraticBezierTo(100, 127, 109, 161)
      ..quadraticBezierTo(112, 177, 126, 186)
      ..quadraticBezierTo(141, 195, 157, 185)
      ..quadraticBezierTo(170, 176, 173, 160)
      ..quadraticBezierTo(180, 125, 167, 95)
      ..quadraticBezierTo(141, 88, 112, 95)
      ..close();
    canvas
      ..drawPath(torso, body)
      ..drawPath(torso, edge);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(140, 76), width: 23, height: 28),
        const Radius.circular(8),
      ),
      body,
    );
    canvas
      ..drawOval(
        Rect.fromCenter(center: const Offset(140, 50), width: 48, height: 54),
        body,
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(140, 50), width: 48, height: 54),
        edge,
      );
    _limb(
      canvas,
      const Offset(111, 104),
      const Offset(84, 145),
      18,
      body,
      edge,
    );
    _limb(canvas, const Offset(84, 145), const Offset(70, 177), 15, body, edge);
    _limb(
      canvas,
      const Offset(170, 104),
      const Offset(194, 145),
      18,
      body,
      edge,
    );
    _limb(
      canvas,
      const Offset(194, 145),
      const Offset(211, 171),
      15,
      body,
      edge,
    );

    final shortsPath = Path()
      ..moveTo(113, 169)
      ..quadraticBezierTo(139, 181, 167, 169)
      ..lineTo(177, 201)
      ..lineTo(150, 202)
      ..lineTo(140, 192)
      ..lineTo(128, 202)
      ..lineTo(102, 199)
      ..close();
    canvas
      ..drawPath(shortsPath, shorts)
      ..drawPath(shortsPath, edge);

    // Iliopsoas: a deep-muscle window, not a surface hip patch.
    final pelvicWindow = Path()
      ..moveTo(117, 143)
      ..quadraticBezierTo(123, 136, 132, 141)
      ..quadraticBezierTo(137, 153, 133, 167)
      ..quadraticBezierTo(126, 174, 119, 166)
      ..close();
    canvas.drawPath(pelvicWindow, window);
    final iliopsoas = Path()
      ..moveTo(124, 143)
      ..quadraticBezierTo(129, 149, 128, 157)
      ..quadraticBezierTo(127, 164, 124, 169)
      ..lineTo(120, 166)
      ..quadraticBezierTo(123, 156, 120, 147)
      ..close();
    canvas.drawPath(iliopsoas, lavender);

    // Rear-leg front: narrow rectus femoris, then separate lateral strip.
    // Both are deliberately drawn after the shorts to remain visible on fabric.
    final rectusFemoris = Path()
      ..moveTo(112, 188)
      ..quadraticBezierTo(98, 204, 86, 224)
      ..quadraticBezierTo(79, 235, 75, 243)
      ..lineTo(65, 238)
      ..quadraticBezierTo(72, 224, 82, 210)
      ..quadraticBezierTo(94, 193, 105, 184)
      ..close();
    canvas.drawPath(rectusFemoris, lavender);
    final vastusLateralis = Path()
      ..moveTo(102, 189)
      ..quadraticBezierTo(87, 205, 75, 224)
      ..lineTo(66, 219)
      ..quadraticBezierTo(77, 199, 94, 185)
      ..close();
    canvas.drawPath(
      vastusLateralis,
      lavender..color = lavender.color.withValues(alpha: 0.45),
    );
    lavender.color = const Color(
      0xff9A7AD3,
    ).withValues(alpha: 0.62 + phase * 0.20);

    canvas.drawArc(
      Rect.fromCenter(center: const Offset(137, 183), width: 76, height: 45),
      3.45,
      2.05,
      false,
      cue,
    );
    final legend = TextPainter(
      text: const TextSpan(
        text: '연보라 · 장요근 · 대퇴직근 · 외측광근 이완',
        style: TextStyle(
          color: Color(0xff805EC5),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 250);
    legend.paint(canvas, Offset(140 - legend.width / 2, 304));
    canvas.restore();
  }

  void _limb(
    Canvas canvas,
    Offset start,
    Offset end,
    double width,
    Paint body,
    Paint edge,
  ) {
    final border = Paint()
      ..color = edge.color
      ..strokeWidth = width + 3
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = body.color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(start, end, border)
      ..drawLine(start, end, fill);
  }

  @override
  bool shouldRepaint(covariant _HipFlexorAnatomyPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

// Kept only as a reference while the new anatomy guide is tuned.
// ignore: unused_element
class _LegacyExerciseFigurePainter extends CustomPainter {
  final double phase;
  final FigureAnimation animation;
  final MoveRole role;
  final String target;

  const _LegacyExerciseFigurePainter({
    required this.phase,
    required this.animation,
    required this.role,
    required this.target,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 260, size.height / 300);
    final offset = Offset(
      (size.width - 260 * scale) / 2,
      (size.height - 300 * scale) / 2,
    );
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final base = Paint()
      ..color = const Color(0xffDDE1EC)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    final outline = Paint()
      ..color = const Color(0xff62697D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final highlight = Paint()
      ..color =
          (role == MoveRole.release
                  ? const Color(0xffF39A6B)
                  : const Color(0xff47B68A))
              .withValues(alpha: 0.48 + phase * 0.28);
    final guide = Paint()
      ..color = const Color(0xff725AC1).withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final swing = (phase - 0.5) * 2;
    var head = const Offset(130, 55);
    var leftHand = const Offset(82, 126);
    var rightHand = const Offset(178, 126);
    var leftElbow = const Offset(99, 108);
    var rightElbow = const Offset(161, 108);
    var torsoLean = 0.0;

    switch (animation) {
      case FigureAnimation.chestOpen:
        leftHand = Offset(64, 118 - 10 * phase);
        rightHand = Offset(196, 118 - 10 * phase);
        leftElbow = Offset(93, 112 - 4 * phase);
        rightElbow = Offset(167, 112 - 4 * phase);
        torsoLean = -3 * phase;
      case FigureAnimation.scapularSet:
        leftHand = Offset(105 + 16 * phase, 139);
        rightHand = Offset(155 - 16 * phase, 139);
        leftElbow = Offset(82 + 18 * phase, 120);
        rightElbow = Offset(178 - 18 * phase, 120);
      case FigureAnimation.neckRelease:
        head = Offset(130 + 17 * swing, 55);
      case FigureAnimation.chinTuck:
        head = Offset(130 - 8 * phase, 55 + 4 * phase);
      case FigureAnimation.upperBackReach:
        leftHand = Offset(120, 132 + 16 * phase);
        rightHand = Offset(140, 132 + 16 * phase);
        leftElbow = Offset(100, 112 + 12 * phase);
        rightElbow = Offset(160, 112 + 12 * phase);
        torsoLean = 6 * phase;
      case FigureAnimation.wallY:
        leftHand = Offset(79, 67 - 10 * phase);
        rightHand = Offset(181, 67 - 10 * phase);
        leftElbow = Offset(98, 89 - 8 * phase);
        rightElbow = Offset(162, 89 - 8 * phase);
      case FigureAnimation.shoulderRoll:
        final circle = phase * math.pi * 2;
        leftElbow = Offset(
          97 + math.cos(circle) * 8,
          106 + math.sin(circle) * 8,
        );
        rightElbow = Offset(
          163 + math.cos(circle) * 8,
          106 + math.sin(circle) * 8,
        );
      case FigureAnimation.hipFlexor:
        torsoLean = -10 * phase;
      case FigureAnimation.gluteSet:
        torsoLean = 4 * phase;
    }

    final shoulderLeft = Offset(108 + torsoLean, 96);
    final shoulderRight = Offset(152 + torsoLean, 96);
    final hip = Offset(130 + torsoLean, 175);

    // Legs.
    canvas.drawLine(hip, Offset(98 + torsoLean, 247), base);
    canvas.drawLine(hip, Offset(162 + torsoLean, 247), base);
    canvas.drawLine(hip, Offset(98 + torsoLean, 247), outline);
    canvas.drawLine(hip, Offset(162 + torsoLean, 247), outline);

    // Torso and head.
    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(130 + torsoLean, 137),
        width: 53,
        height: 86,
      ),
      const Radius.circular(25),
    );
    canvas.drawRRect(torso, base..style = PaintingStyle.fill);
    canvas.drawRRect(torso, outline);
    canvas.drawCircle(head, 23, base..style = PaintingStyle.fill);
    canvas.drawCircle(head, 23, outline);

    // Arms.
    canvas.drawLine(shoulderLeft, leftElbow, base);
    canvas.drawLine(leftElbow, leftHand, base);
    canvas.drawLine(shoulderRight, rightElbow, base);
    canvas.drawLine(rightElbow, rightHand, base);
    canvas.drawLine(shoulderLeft, leftElbow, outline);
    canvas.drawLine(leftElbow, leftHand, outline);
    canvas.drawLine(shoulderRight, rightElbow, outline);
    canvas.drawLine(rightElbow, rightHand, outline);

    _drawHighlight(
      canvas,
      highlight,
      torso,
      head,
      shoulderLeft,
      shoulderRight,
      hip,
    );
    _drawMotionHint(canvas, guide, head, shoulderLeft, shoulderRight, hip);

    final textPainter = TextPainter(
      text: TextSpan(
        text: target,
        style: const TextStyle(
          color: Color(0xff5C6170),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);
    textPainter.paint(canvas, Offset(130 - textPainter.width / 2, 270));
    canvas.restore();
  }

  void _drawHighlight(
    Canvas canvas,
    Paint highlight,
    RRect torso,
    Offset head,
    Offset shoulderLeft,
    Offset shoulderRight,
    Offset hip,
  ) {
    if (target.contains('목')) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(head.dx, head.dy + 28),
            width: 20,
            height: 25,
          ),
          const Radius.circular(9),
        ),
        highlight,
      );
    }
    if (target.contains('가슴')) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(torso.center.dx, 124),
            width: 43,
            height: 32,
          ),
          const Radius.circular(16),
        ),
        highlight,
      );
    }
    if (target.contains('등')) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(torso.center.dx, 145),
            width: 45,
            height: 42,
          ),
          const Radius.circular(18),
        ),
        highlight,
      );
    }
    if (target.contains('어깨')) {
      canvas.drawCircle(shoulderLeft, 15, highlight);
      canvas.drawCircle(shoulderRight, 15, highlight);
    }
    if (target.contains('골반') || target.contains('엉덩이')) {
      canvas.drawOval(
        Rect.fromCenter(center: hip, width: 58, height: 28),
        highlight,
      );
    }
  }

  void _drawMotionHint(
    Canvas canvas,
    Paint guide,
    Offset head,
    Offset shoulderLeft,
    Offset shoulderRight,
    Offset hip,
  ) {
    switch (animation) {
      case FigureAnimation.neckRelease:
      case FigureAnimation.chinTuck:
        canvas.drawArc(
          Rect.fromCenter(center: head, width: 68, height: 54),
          -0.9,
          1.8,
          false,
          guide,
        );
      case FigureAnimation.chestOpen:
      case FigureAnimation.scapularSet:
      case FigureAnimation.wallY:
      case FigureAnimation.shoulderRoll:
        canvas.drawArc(
          Rect.fromCenter(center: shoulderLeft, width: 43, height: 43),
          1.9,
          2.0,
          false,
          guide,
        );
        canvas.drawArc(
          Rect.fromCenter(center: shoulderRight, width: 43, height: 43),
          -0.7,
          2.0,
          false,
          guide,
        );
      case FigureAnimation.upperBackReach:
        canvas.drawLine(const Offset(130, 102), const Offset(130, 150), guide);
      case FigureAnimation.hipFlexor:
      case FigureAnimation.gluteSet:
        canvas.drawArc(
          Rect.fromCenter(center: hip, width: 80, height: 48),
          3.3,
          2.6,
          false,
          guide,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _LegacyExerciseFigurePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.animation != animation ||
        oldDelegate.role != role ||
        oldDelegate.target != target;
  }
}

// ignore: unused_element
class _ExerciseFigurePainter extends CustomPainter {
  final double phase;
  final FigureAnimation animation;
  final MoveRole role;
  final String target;

  const _ExerciseFigurePainter({
    required this.phase,
    required this.animation,
    required this.role,
    required this.target,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 280, size.height / 320);
    final origin = Offset(
      (size.width - 280 * scale) / 2,
      (size.height - 320 * scale) / 2,
    );
    canvas
      ..save()
      ..translate(origin.dx, origin.dy)
      ..scale(scale);

    final pulse = Curves.easeInOut.transform(phase);
    final activationColor = const Color(0xffF08A52);
    final releaseColor = const Color(0xff9A7AD3);
    final emphasis = role == MoveRole.release ? releaseColor : activationColor;
    final body = Paint()..color = const Color(0xffE8EAF0);
    final edge = Paint()
      ..color = const Color(0xff73798A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;
    final muscleLine = Paint()
      ..color = const Color(0xffBEC4D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = emphasis.withValues(alpha: 0.50 + pulse * 0.32)
      ..style = PaintingStyle.fill;
    final arrow = Paint()
      ..color = emphasis.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final swing = math.sin(phase * math.pi) * 18;
    var lean = 0.0;
    var headShift = Offset.zero;
    var leftHand = const Offset(72, 145);
    var rightHand = const Offset(208, 145);
    var leftElbow = const Offset(95, 119);
    var rightElbow = const Offset(185, 119);

    switch (animation) {
      case FigureAnimation.chestOpen:
        lean = -3 * pulse;
        leftHand = Offset(51, 137 - 10 * pulse);
        rightHand = Offset(229, 137 - 10 * pulse);
        leftElbow = Offset(91, 114 - 4 * pulse);
        rightElbow = Offset(189, 114 - 4 * pulse);
      case FigureAnimation.scapularSet:
        leftHand = Offset(121 + 18 * pulse, 146);
        rightHand = Offset(159 - 18 * pulse, 146);
        leftElbow = Offset(86 + 22 * pulse, 123);
        rightElbow = Offset(194 - 22 * pulse, 123);
      case FigureAnimation.neckRelease:
        headShift = Offset(swing, 1.5 * pulse);
      case FigureAnimation.chinTuck:
        headShift = Offset(-9 * pulse, 5 * pulse);
      case FigureAnimation.upperBackReach:
        lean = 6 * pulse;
        leftHand = Offset(126, 165 + 18 * pulse);
        rightHand = Offset(154, 165 + 18 * pulse);
        leftElbow = Offset(98, 124 + 14 * pulse);
        rightElbow = Offset(182, 124 + 14 * pulse);
      case FigureAnimation.wallY:
        leftHand = Offset(76, 62 - 12 * pulse);
        rightHand = Offset(204, 62 - 12 * pulse);
        leftElbow = Offset(100, 91 - 10 * pulse);
        rightElbow = Offset(180, 91 - 10 * pulse);
      case FigureAnimation.shoulderRoll:
        final angle = phase * math.pi * 2;
        leftElbow = Offset(
          96 + math.cos(angle) * 10,
          119 + math.sin(angle) * 10,
        );
        rightElbow = Offset(
          184 + math.cos(angle) * 10,
          119 + math.sin(angle) * 10,
        );
      case FigureAnimation.hipFlexor:
        lean = -11 * pulse;
      case FigureAnimation.gluteSet:
        lean = 4 * pulse;
    }

    final shoulderLeft = Offset(108 + lean, 103);
    final shoulderRight = Offset(172 + lean, 103);
    final neck = Offset(140 + lean, 77) + headShift;
    final head = Offset(140, 51) + headShift;
    final pelvis = Offset(140 + lean, 190);

    // Soft ground shadow gives the figure depth without a face or clothing.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(140, 285), width: 118, height: 14),
      Paint()..color = const Color(0xffBAC0CF).withValues(alpha: 0.25),
    );

    _limb(canvas, pelvis, Offset(103 + lean, 270), 24, body, edge);
    _limb(canvas, pelvis, Offset(177 + lean, 270), 24, body, edge);

    final torso = Path()
      ..moveTo(114 + lean, 98)
      ..quadraticBezierTo(101 + lean, 128, 109 + lean, 162)
      ..quadraticBezierTo(113 + lean, 183, 122 + lean, 193)
      ..quadraticBezierTo(140 + lean, 202, 158 + lean, 193)
      ..quadraticBezierTo(167 + lean, 183, 171 + lean, 162)
      ..quadraticBezierTo(179 + lean, 128, 166 + lean, 98)
      ..quadraticBezierTo(140 + lean, 89, 114 + lean, 98)
      ..close();
    canvas.drawPath(torso, body);
    canvas.drawPath(torso, edge);

    // Neck and faceless anatomical head.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: neck, width: 24, height: 29),
        const Radius.circular(8),
      ),
      body,
    );
    canvas.drawOval(Rect.fromCenter(center: head, width: 48, height: 54), body);
    canvas.drawOval(Rect.fromCenter(center: head, width: 48, height: 54), edge);

    _limb(canvas, shoulderLeft, leftElbow, 18, body, edge);
    _limb(canvas, leftElbow, leftHand, 15, body, edge);
    _limb(canvas, shoulderRight, rightElbow, 18, body, edge);
    _limb(canvas, rightElbow, rightHand, 15, body, edge);

    _drawAnatomyLines(canvas, muscleLine, torso, neck, pelvis);
    _drawTarget(canvas, glow, torso, neck, shoulderLeft, shoulderRight, pelvis);
    _drawMotionCue(canvas, arrow, head, shoulderLeft, shoulderRight, pelvis);

    final legend = TextPainter(
      text: TextSpan(
        text: role == MoveRole.release
            ? '연보라 표시 · 천천히 이완하는 부위'
            : '주황 표시 · 가볍게 활성화하는 부위',
        style: TextStyle(
          color: emphasis,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 240);
    legend.paint(canvas, Offset(140 - legend.width / 2, 300));
    canvas.restore();
  }

  void _limb(
    Canvas canvas,
    Offset start,
    Offset end,
    double width,
    Paint body,
    Paint edge,
  ) {
    final limb = Paint()
      ..color = body.color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final limbEdge = Paint()
      ..color = edge.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 3
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(start, end, limbEdge)
      ..drawLine(start, end, limb);
  }

  void _drawAnatomyLines(
    Canvas canvas,
    Paint line,
    Path torso,
    Offset neck,
    Offset pelvis,
  ) {
    canvas.drawPath(torso, line);
    canvas.drawLine(
      Offset(neck.dx, neck.dy + 12),
      Offset(pelvis.dx, pelvis.dy),
      line,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(pelvis.dx, 133), width: 46, height: 36),
      0.2,
      2.7,
      false,
      line,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(pelvis.dx, 133), width: 46, height: 36),
      3.35,
      2.7,
      false,
      line,
    );
  }

  void _drawTarget(
    Canvas canvas,
    Paint highlight,
    Path torso,
    Offset neck,
    Offset shoulderLeft,
    Offset shoulderRight,
    Offset pelvis,
  ) {
    if (target.contains('목')) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(neck.dx, neck.dy + 9),
            width: 23,
            height: 31,
          ),
          const Radius.circular(9),
        ),
        highlight,
      );
    }
    if (target.contains('가슴')) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pelvis.dx - 13, 129),
          width: 27,
          height: 25,
        ),
        highlight,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pelvis.dx + 13, 129),
          width: 27,
          height: 25,
        ),
        highlight,
      );
    }
    if (target.contains('등')) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(pelvis.dx, 148),
            width: 50,
            height: 49,
          ),
          const Radius.circular(18),
        ),
        highlight,
      );
    }
    if (target.contains('어깨')) {
      canvas
        ..drawCircle(shoulderLeft, 18, highlight)
        ..drawCircle(shoulderRight, 18, highlight);
    }
    if (target.contains('골반') || target.contains('엉덩이')) {
      canvas.drawOval(
        Rect.fromCenter(center: pelvis, width: 64, height: 33),
        highlight,
      );
    }
  }

  void _drawMotionCue(
    Canvas canvas,
    Paint arrow,
    Offset head,
    Offset shoulderLeft,
    Offset shoulderRight,
    Offset pelvis,
  ) {
    if (animation == FigureAnimation.neckRelease ||
        animation == FigureAnimation.chinTuck) {
      canvas.drawArc(
        Rect.fromCenter(center: head, width: 70, height: 55),
        -0.9,
        1.8,
        false,
        arrow,
      );
      return;
    }
    if (animation == FigureAnimation.hipFlexor ||
        animation == FigureAnimation.gluteSet) {
      canvas.drawArc(
        Rect.fromCenter(center: pelvis, width: 88, height: 52),
        3.3,
        2.55,
        false,
        arrow,
      );
      return;
    }
    canvas.drawArc(
      Rect.fromCenter(center: shoulderLeft, width: 47, height: 47),
      1.8,
      2.1,
      false,
      arrow,
    );
    canvas.drawArc(
      Rect.fromCenter(center: shoulderRight, width: 47, height: 47),
      -0.75,
      2.1,
      false,
      arrow,
    );
  }

  @override
  bool shouldRepaint(covariant _ExerciseFigurePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.animation != animation ||
        oldDelegate.role != role ||
        oldDelegate.target != target;
  }
}

CorrectiveRoutine _routineFor(String profileId) {
  final routines = switch (profileId) {
    'forward' => _forwardRoutines,
    'slouch' => _slouchRoutines,
    _ => _balancedRoutines,
  };

  final today = DateTime.now();
  final int seed =
      today.year * 10000 +
      today.month * 100 +
      today.day +
      profileId.codeUnits.fold<int>(0, (sum, codeUnit) => sum + codeUnit);
  return routines[seed % routines.length];
}

final _forwardRoutines = <CorrectiveRoutine>[
  CorrectiveRoutine(
    title: 'FLS-A 교정 루틴',
    emoji: '🐢🦊',
    message: '거북목 탐험가를 위한 오늘의 조합이에요.\n가슴을 풀고, 목·등 지지력을 깨워요.',
    pairs: [
      CorrectivePair(
        title: '가슴 열기 → 견갑 고정',
        description: '앞쪽의 답답함을 줄이고 어깨를 편하게 뒤로 지지해요.',
        release: CorrectiveMove(
          title: '서서 가슴 열기',
          target: '가슴·어깨',
          guide: '깍지 낀 손을 등 뒤로 보내고, 가슴을 편하게 열어주세요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.chestOpen,
        ),
        activate: CorrectiveMove(
          title: '벽 없이 견갑 조이기',
          target: '등·어깨',
          guide: '팔꿈치를 뒤로 끌어당기듯, 날개뼈를 가볍게 모아 2초 버텨요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.scapularSet,
        ),
      ),
      CorrectivePair(
        title: '목 옆 이완 → 턱 당기기',
        description: '목 주변 긴장을 줄인 뒤, 고개 위치 감각을 다시 잡아요.',
        release: CorrectiveMove(
          title: '목 옆 부드럽게 늘리기',
          target: '목',
          guide: '어깨는 내리고, 귀를 어깨 쪽으로 아주 천천히 기울여요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.neckRelease,
        ),
        activate: CorrectiveMove(
          title: '서서 턱 당기기',
          target: '목',
          guide: '시선은 정면에 두고, 턱을 수평으로 살짝 뒤로 당겨요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.chinTuck,
        ),
      ),
    ],
  ),
  CorrectiveRoutine(
    title: 'FLS-A 교정 루틴',
    emoji: '🐢🦊',
    message: '거북목 탐험가를 위한 오늘의 조합이에요.\n상체를 길게 펴고, 자세 지지 근육을 깨워요.',
    pairs: [
      CorrectivePair(
        title: '등 길게 만들기 → Y 자세',
        description: '굽은 상체를 부드럽게 펴고 어깨 위쪽 움직임을 만들어요.',
        release: CorrectiveMove(
          title: '서서 등 길게 늘리기',
          target: '등',
          guide: '두 손을 앞으로 뻗으며 등을 둥글고 길게 늘려주세요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.upperBackReach,
        ),
        activate: CorrectiveMove(
          title: '서서 Y 팔 들기',
          target: '등·어깨',
          guide: '팔을 Y자로 천천히 들고, 어깨가 귀로 올라가지 않게 해요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.wallY,
        ),
      ),
      CorrectivePair(
        title: '대퇴직근 이완 → 둔근 강화',
        description: '앞허벅지를 충분히 늘린 뒤, 둔근으로 골반을 안정적으로 지지해요.',
        release: CorrectiveMove(
          title: '서서 대퇴직근 스트레칭',
          target: '대퇴직근',
          guide: '한쪽 발목을 잡아 뒤로 당기고, 무릎은 가까이 둔 채 앞허벅지를 편하게 늘려요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.hipFlexor,
        ),
        activate: CorrectiveMove(
          title: '스탠딩 힙 익스텐션',
          target: '둔근',
          guide: '허리를 꺾지 말고 한쪽 다리를 뒤로 작게 뻗어 둔근에 2초 힘을 주세요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.gluteSet,
        ),
      ),
    ],
  ),
];

final _slouchRoutines = <CorrectiveRoutine>[
  CorrectiveRoutine(
    title: 'SSS-P 교정 루틴',
    emoji: '🐻🦔',
    message: '꾸벅 곰을 위한 오늘의 조합이에요.\n굳은 앞쪽을 풀고, 등을 펴는 힘을 깨워요.',
    pairs: [
      CorrectivePair(
        title: '가슴 열기 → Y 자세',
        description: '앞쪽을 편하게 열고, 등·어깨가 자세를 지지하도록 도와요.',
        release: CorrectiveMove(
          title: '서서 가슴 열기',
          target: '가슴·어깨',
          guide: '양손을 등 뒤로 보내고, 숨을 내쉬며 가슴을 가볍게 열어요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.chestOpen,
        ),
        activate: CorrectiveMove(
          title: '서서 Y 팔 들기',
          target: '등·어깨',
          guide: '팔을 Y자로 들며 어깨를 아래로 길게 유지해요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.wallY,
        ),
      ),
      CorrectivePair(
        title: '등 이완 → 견갑 고정',
        description: '말린 등을 길게 만든 뒤, 날개뼈가 편하게 자리를 찾도록 해요.',
        release: CorrectiveMove(
          title: '서서 등 길게 늘리기',
          target: '등',
          guide: '두 손을 앞으로 보내며 등 뒤가 넓어지는 느낌을 찾아요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.upperBackReach,
        ),
        activate: CorrectiveMove(
          title: '벽 없이 견갑 조이기',
          target: '등·어깨',
          guide: '팔꿈치를 천천히 뒤로 보내며 날개뼈를 가볍게 모아주세요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.scapularSet,
        ),
      ),
    ],
  ),
  CorrectiveRoutine(
    title: 'SSS-P 교정 루틴',
    emoji: '🐻🦔',
    message: '꾸벅 곰을 위한 오늘의 조합이에요.\n목·어깨 긴장을 낮추고 상체를 세워요.',
    pairs: [
      CorrectivePair(
        title: '목 이완 → 턱 당기기',
        description: '목 주변을 부드럽게 풀고 고개가 중심으로 돌아오게 해요.',
        release: CorrectiveMove(
          title: '목 옆 부드럽게 늘리기',
          target: '목',
          guide: '한쪽 귀를 어깨 가까이로 천천히 기울여요. 어깨는 내립니다.',
          seconds: 20,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.neckRelease,
        ),
        activate: CorrectiveMove(
          title: '서서 턱 당기기',
          target: '목',
          guide: '턱을 아래로 누르지 말고 수평으로 살짝 뒤로 당겨요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.chinTuck,
        ),
      ),
      CorrectivePair(
        title: '가슴 열기 → 어깨 돌리기',
        description: '앞쪽을 열고 어깨가 뒤로 부드럽게 움직이게 해요.',
        release: CorrectiveMove(
          title: '서서 가슴 열기',
          target: '가슴·어깨',
          guide: '손을 뒤로 보내고, 허리를 과하게 꺾지 않은 채 가슴을 열어요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.chestOpen,
        ),
        activate: CorrectiveMove(
          title: '어깨 뒤로 천천히 돌리기',
          target: '어깨',
          guide: '어깨를 위·뒤·아래 순서로 천천히 크게 돌려주세요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.shoulderRoll,
        ),
      ),
    ],
  ),
];

final _balancedRoutines = <CorrectiveRoutine>[
  CorrectiveRoutine(
    title: 'BPS-N 유지 루틴',
    emoji: '🐧🦦',
    message: '바른 흐름을 지키는 오늘의 조합이에요.\n가볍게 풀고, 편한 자세를 기억해요.',
    pairs: [
      CorrectivePair(
        title: '목 이완 → 목 위치 기억',
        description: '목 주변의 긴장을 낮추고 정면을 편하게 바라보는 감각을 만들어요.',
        release: CorrectiveMove(
          title: '목 옆 부드럽게 늘리기',
          target: '목',
          guide: '어깨 힘을 빼고, 머리를 좌우로 아주 천천히 기울여요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.neckRelease,
        ),
        activate: CorrectiveMove(
          title: '서서 턱 당기기',
          target: '목',
          guide: '정면을 보며 턱을 살짝 뒤로 당긴 상태를 편하게 유지해요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.chinTuck,
        ),
      ),
      CorrectivePair(
        title: '가슴 열기 → 어깨 돌리기',
        description: '앉아 있던 상체를 부드럽게 열고, 어깨 움직임을 회복해요.',
        release: CorrectiveMove(
          title: '서서 가슴 열기',
          target: '가슴·어깨',
          guide: '등 뒤에서 손을 가볍게 잡고 숨을 내쉬며 가슴을 열어요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.chestOpen,
        ),
        activate: CorrectiveMove(
          title: '어깨 뒤로 천천히 돌리기',
          target: '어깨',
          guide: '어깨를 부드럽게 크게 뒤로 돌리며 목 힘을 빼주세요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.shoulderRoll,
        ),
      ),
    ],
  ),
  CorrectiveRoutine(
    title: 'BPS-N 유지 루틴',
    emoji: '🐧🦦',
    message: '바른 흐름을 지키는 오늘의 조합이에요.\n상체와 골반을 편하게 깨워요.',
    pairs: [
      CorrectivePair(
        title: '등 이완 → Y 자세',
        description: '등을 길게 만든 뒤, 상체를 세우는 움직임을 가볍게 연습해요.',
        release: CorrectiveMove(
          title: '서서 등 길게 늘리기',
          target: '등',
          guide: '두 손을 앞에 두고 등 뒤가 길어지는 느낌으로 숨을 쉬어요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.upperBackReach,
        ),
        activate: CorrectiveMove(
          title: '서서 Y 팔 들기',
          target: '등·어깨',
          guide: '팔을 Y자로 들고, 어깨가 으쓱 올라가지 않게 해요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.wallY,
        ),
      ),
      CorrectivePair(
        title: '대퇴직근 이완 → 둔근 강화',
        description: '앞허벅지를 충분히 늘린 뒤, 둔근으로 골반을 안정적으로 지지해요.',
        release: CorrectiveMove(
          title: '서서 대퇴직근 스트레칭',
          target: '대퇴직근',
          guide: '한쪽 발목을 잡아 뒤로 당기고, 무릎은 가까이 둔 채 앞허벅지를 편하게 늘려요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.hipFlexor,
        ),
        activate: CorrectiveMove(
          title: '스탠딩 힙 익스텐션',
          target: '둔근',
          guide: '허리를 꺾지 말고 한쪽 다리를 뒤로 작게 뻗어 둔근에 2초 힘을 주세요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.gluteSet,
        ),
      ),
    ],
  ),
];

List<_MoveOption> _stretchMoveOptions(MoveRole role) {
  final pairsByTitle = <String, CorrectivePair>{};
  final routines = [..._forwardRoutines, ..._slouchRoutines, ..._balancedRoutines];

  for (final routine in routines) {
    for (final pair in routine.pairs) {
      pairsByTitle.putIfAbsent(pair.title, () => pair);
    }
  }

  for (final pair in _extraStretchPairs) {
    pairsByTitle.putIfAbsent(pair.title, () => pair);
  }

  final optionsByTitle = <String, _MoveOption>{};
  for (final pair in pairsByTitle.values) {
    final move = role == MoveRole.release ? pair.release : pair.activate;
    optionsByTitle.putIfAbsent(
      move.title,
      () => _MoveOption(
        move: move,
        reason: pair.recommendationReason,
        blockedProfileIds: pair.blockedProfileIds,
      ),
    );
  }
  final options = optionsByTitle.values.toList()
    ..sort((a, b) => a.move.title.compareTo(b.move.title));
  return options;
}

class _MoveOption {
  final CorrectiveMove move;
  final String reason;
  final Set<String> blockedProfileIds;

  const _MoveOption({
    required this.move,
    required this.reason,
    required this.blockedProfileIds,
  });
}

final _extraStretchPairs = <CorrectivePair>[
  CorrectivePair(
    title: '벽 가슴 열기 → 벽 Y 팔 들기',
    description: '벽을 이용해 앞가슴을 부드럽게 열고, 등·어깨 지지력을 깨워요.',
    category: '벽 활용',
    recommendationReason: '오래 앉아 굳기 쉬운 가슴과 어깨 앞쪽을 편하게 움직이는 데 도움이 되는 기본 조합이에요.',
    release: CorrectiveMove(
      title: '벽 짚고 가슴 열기',
      target: '가슴·어깨 앞쪽',
      guide: '벽에 손을 가볍게 대고 몸통을 반대쪽으로 천천히 열어요. 어깨가 아프면 범위를 줄여요.',
      seconds: 20,
      sets: 2,
      role: MoveRole.release,
      animation: FigureAnimation.chestOpen,
    ),
    activate: CorrectiveMove(
      title: '벽 Y 팔 들기',
      target: '등·어깨',
      guide: '벽 가까이 서서 팔을 Y자로 올리고, 어깨를 아래로 길게 유지해요.',
      seconds: 20,
      sets: 2,
      role: MoveRole.activate,
      animation: FigureAnimation.wallY,
    ),
  ),
  CorrectivePair(
    title: '기둥 몸통 열기 → 스탠딩 힙 익스텐션',
    description: '기둥이나 문틀을 가볍게 잡고 몸통을 열어준 뒤, 둔근을 깨워요.',
    category: '기둥 활용',
    recommendationReason: '앉아 있는 시간이 긴 날, 몸통 움직임과 골반 주변의 가벼운 활성화를 함께 챙길 수 있는 조합이에요.',
    release: CorrectiveMove(
      title: '기둥 잡고 몸통 열기',
      target: '옆구리·등',
      guide: '기둥이나 문틀을 한 손으로 잡고, 몸을 반대 방향으로 살짝 돌려 옆구리를 편하게 열어요.',
      seconds: 20,
      sets: 2,
      role: MoveRole.release,
      animation: FigureAnimation.upperBackReach,
    ),
    activate: CorrectiveMove(
      title: '스탠딩 힙 익스텐션',
      target: '둔근',
      guide: '허리를 꺾지 말고 한쪽 다리를 뒤로 작게 뻗어 둔근에 2초 힘을 주세요.',
      seconds: 20,
      sets: 2,
      role: MoveRole.activate,
      animation: FigureAnimation.gluteSet,
    ),
  ),
  CorrectivePair(
    title: '강한 허리 젖히기 → 등 펴기',
    description: '허리를 크게 젖히는 동작이 포함된 조합이에요.',
    category: '주의 동작',
    recommendationReason: '현재 자세 경향에서는 허리 부담이 커질 수 있어 기본 루틴으로 권하지 않아요.',
    blockedProfileIds: const {'forward'},
    release: CorrectiveMove(
      title: '서서 허리 젖히기',
      target: '몸통 앞쪽',
      guide: '통증 없이 가능한 범위에서만 아주 작게 젖혀요.',
      seconds: 15,
      sets: 2,
      role: MoveRole.release,
      animation: FigureAnimation.chestOpen,
    ),
    activate: CorrectiveMove(
      title: '벽 없이 견갑 조이기',
      target: '등·어깨',
      guide: '팔꿈치를 천천히 뒤로 보내며 날개뼈를 가볍게 모아주세요.',
      seconds: 20,
      sets: 2,
      role: MoveRole.activate,
      animation: FigureAnimation.scapularSet,
    ),
  ),
  CorrectivePair(
    title: '강한 등 말기 → 어깨 정리',
    description: '등을 크게 둥글게 만드는 동작이 포함된 조합이에요.',
    category: '주의 동작',
    recommendationReason: '현재 자세 경향에서는 이미 말린 느낌을 키울 수 있어 기본 루틴으로 권하지 않아요.',
    blockedProfileIds: const {'slouch'},
    release: CorrectiveMove(
      title: '서서 등 크게 말기',
      target: '등',
      guide: '팔을 앞으로 보내고 등을 가볍게 둥글게 만들어요.',
      seconds: 15,
      sets: 2,
      role: MoveRole.release,
      animation: FigureAnimation.upperBackReach,
    ),
    activate: CorrectiveMove(
      title: '어깨 뒤로 천천히 돌리기',
      target: '어깨',
      guide: '어깨를 위·뒤·아래 순서로 천천히 크게 돌려주세요.',
      seconds: 20,
      sets: 2,
      role: MoveRole.activate,
      animation: FigureAnimation.shoulderRoll,
    ),
  ),
];

enum MoveRole { release, activate }

enum FigureAnimation {
  chestOpen,
  scapularSet,
  neckRelease,
  chinTuck,
  upperBackReach,
  wallY,
  shoulderRoll,
  hipFlexor,
  gluteSet,
}

class CorrectiveRoutine {
  final String title;
  final String emoji;
  final String message;
  final List<CorrectivePair> pairs;

  const CorrectiveRoutine({
    required this.title,
    required this.emoji,
    required this.message,
    required this.pairs,
  });

  List<CorrectiveMove> get moves => [
    for (final pair in pairs) pair.release,
    for (final pair in pairs) pair.activate,
  ];

  CorrectiveRoutine copyWith({List<CorrectivePair>? pairs}) {
    return CorrectiveRoutine(
      title: title,
      emoji: emoji,
      message: message,
      pairs: pairs ?? this.pairs,
    );
  }
}

class CorrectivePair {
  final String title;
  final String description;
  final CorrectiveMove release;
  final CorrectiveMove activate;
  final String category;
  final String recommendationReason;
  final Set<String> blockedProfileIds;

  const CorrectivePair({
    required this.title,
    required this.description,
    required this.release,
    required this.activate,
    this.category = '자세 리셋',
    this.recommendationReason = '오래 앉아 있는 동안 굳기 쉬운 부위를 부드럽게 움직이고, 편한 자세를 유지하는 데 도움을 주는 조합이에요.',
    this.blockedProfileIds = const {},
  });

  CorrectivePair copyWith({
    CorrectiveMove? release,
    CorrectiveMove? activate,
  }) {
    return CorrectivePair(
      title: title,
      description: description,
      release: release ?? this.release,
      activate: activate ?? this.activate,
      category: category,
      recommendationReason: recommendationReason,
      blockedProfileIds: blockedProfileIds,
    );
  }
}

class CorrectiveMove {
  final String title;
  final String target;
  final String guide;
  final int seconds;
  final int sets;
  final MoveRole role;
  final FigureAnimation animation;

  const CorrectiveMove({
    required this.title,
    required this.target,
    required this.guide,
    required this.seconds,
    required this.sets,
    required this.role,
    required this.animation,
  });
}
