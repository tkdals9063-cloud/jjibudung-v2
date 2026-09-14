import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/posture_companion.dart';
import '../services/storage_service.dart';

/// 팬더의 좌·우 압력 편향을 스트레칭 추천에 전달하는 값이다.
/// 실제 센서 어댑터는 좌석 좌·우 압력의 우세 쪽을 이 값으로 넘긴다.
enum PandaLeanSide { left, right }

class StretchRecommendationScreen extends StatefulWidget {
  final String profileId;
  final PandaLeanSide? pandaLeanSide;

  const StretchRecommendationScreen({
    super.key,
    this.profileId = 'balanced',
    this.pandaLeanSide,
  });

  @override
  State<StretchRecommendationScreen> createState() =>
      _StretchRecommendationScreenState();
}

class _StretchProfilePortrait extends StatelessWidget {
  final PostureCompanionPair companion;

  const _StretchProfilePortrait({required this.companion});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        _CompanionChip(
          icon: Icons.explore_rounded,
          label: companion.explorer.name,
          color: const Color(0xff725AC1),
        ),
        _CompanionChip(
          icon: Icons.pets_rounded,
          label: companion.pet.name,
          color: const Color(0xffD96B42),
        ),
      ],
    );
  }
}

class _CompanionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompanionChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StretchRecommendationScreenState
    extends State<StretchRecommendationScreen> {
  int? _completedToday;
  late CorrectiveRoutine _routine;
  late final PostureCompanionPair _companion;

  @override
  void initState() {
    super.initState();
    _routine = _routineFor(
      widget.profileId,
      pandaLeanSide: widget.pandaLeanSide,
    );
    _companion = pairForLegacyProfile(widget.profileId);
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
        builder: (_) => CorrectiveRoutineScreen(
          routine: _routine,
          profileId: widget.profileId,
        ),
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
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      decoration: BoxDecoration(
                        color: const Color(0xffF5F1FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          _StretchProfilePortrait(companion: _companion),
                          const SizedBox(height: 12),
                          Text(
                            _routine.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      '오늘의 맞춤 교정 루틴',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '탐험가 상체 1쌍 + 펫 하체·골반 1쌍으로 구성했어요.',
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
                            companionLabel: entry.key == 0
                                ? _companion.explorer.name
                                : _companion.pet.name,
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
                            companionLabel: entry.key == 0
                                ? _companion.explorer.name
                                : _companion.pet.name,
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
    final pairs = [..._routine.pairs];
    final existingMoveIndex = pairs.indexWhere(
      (pair) =>
          pair != currentPair &&
          (role == MoveRole.release ? pair.release : pair.activate).title ==
              selected.title,
    );

    pairs[pairIndex] = replacement;
    if (existingMoveIndex != -1) {
      final existingPair = pairs[existingMoveIndex];
      pairs[existingMoveIndex] = existingPair.copyWith(
        release: role == MoveRole.release ? currentMove : null,
        activate: role == MoveRole.activate ? currentMove : null,
      );
    }

    setState(() => _routine = _routine.copyWith(pairs: pairs));
  }

  void _showRecommendationReason(CorrectivePair pair) {
    final isBlocked = pair.blockedProfileIds.contains(widget.profileId);
    final accentColor = isBlocked
        ? const Color(0xffC84D4D)
        : const Color(0xff725AC1);
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
              Row(
                children: [
                  Icon(
                    isBlocked
                        ? Icons.thumb_down_alt_rounded
                        : Icons.thumb_up_alt_rounded,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBlocked ? '왜 이 조합을 비추천하나요?' : '왜 이 조합을 추천하나요?',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(pair.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(pair.recommendationReason, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 12),
              Text(
                isBlocked
                    ? '현재 자세 경향에는 부담을 키울 수 있어 기본 루틴에서 제외해요. 통증이 있으면 진행하지 마세요.'
                    : '측정으로 파악한 자세 경향을 바탕으로 우선순위를 정한 안내예요. 통증이 있으면 진행하지 마세요.',
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.45),
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
  final String companionLabel;
  final VoidCallback onSwap;
  final VoidCallback onInfo;

  const _RoutineMoveCard({
    required this.number,
    required this.move,
    required this.companionLabel,
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
                Text(
                  '$companionLabel · ${move.target} · ${move.sets}세트',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
    final blockedColor = const Color(0xffC84D4D);
    final background = isBlocked ? const Color(0xffFFF4F3) : Colors.white;
    final textColor = isBlocked ? const Color(0xffA84A4A) : const Color(0xff24232A);
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
              Icon(
                isBlocked ? Icons.thumb_down_alt_outlined : Icons.self_improvement_rounded,
                color: isBlocked ? blockedColor : const Color(0xff725AC1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(option.move.title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                        _PickerLabel(
                          text: isBlocked ? '비추천' : isCurrent ? '현재 선택됨' : '추천',
                          color: isBlocked
                              ? blockedColor
                              : isCurrent
                              ? const Color(0xff725AC1)
                              : const Color(0xff3C8E6B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(option.move.target, style: TextStyle(color: textColor)),
                    const SizedBox(height: 6),
                    Text(
                      option.reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: isBlocked ? const Color(0xffA84A4A) : Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
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
  final String profileId;

  const CorrectiveRoutineScreen({
    super.key,
    required this.routine,
    required this.profileId,
  });

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
  _QuadricepsMotionPhase _quadricepsPhase = _QuadricepsMotionPhase.neutral;

  CorrectiveMove get _move => widget.routine.moves[_moveIndex];

  bool get _isTimedGuideMove =>
      _move.resolvedVideoAssetPath != null ||
      (_move.animation == FigureAnimation.hipFlexor &&
          widget.profileId == 'balanced') ||
      _move.animation == FigureAnimation.neckRelease ||
      (_move.animation == FigureAnimation.chestOpen &&
          _move.title != '서서 허리 젖히기');

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
      _quadricepsPhase = _isTimedGuideMove
          ? _QuadricepsMotionPhase.raising
          : _QuadricepsMotionPhase.neutral;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _isRunning = false;
          _quadricepsPhase = _QuadricepsMotionPhase.neutral;
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
        _quadricepsPhase = _QuadricepsMotionPhase.neutral;
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
                    profileId: widget.profileId,
                    quadricepsPhase: _quadricepsPhase,
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
  final String profileId;
  final _QuadricepsMotionPhase quadricepsPhase;

  const _SmoothExerciseGuide({
    required this.controller,
    required this.move,
    required this.profileId,
    required this.quadricepsPhase,
  });

  @override
  Widget build(BuildContext context) {
    if (move.resolvedVideoAssetPath != null) {
      return _TimedAssetGuide(
        key: ValueKey('${move.title}:${move.resolvedVideoAssetPath}'),
        phase: quadricepsPhase,
        assetPath: move.resolvedVideoAssetPath!,
      );
    }

    if (move.animation == FigureAnimation.chestOpen &&
        move.title != '서서 허리 젖히기') {
      return _TimedAssetGuide(
        key: ValueKey('${move.title}:pec'),
        phase: quadricepsPhase,
        assetPath: 'assets/exercise/pec_stretch_clean_hold20_reverse.mp4',
      );
    }

    if (move.animation == FigureAnimation.neckRelease) {
      return _TimedAssetGuide(
        key: ValueKey('${move.title}:neck'),
        phase: quadricepsPhase,
        assetPath: 'assets/exercise/neck_stretch_clean_white_v2.mp4',
      );
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

enum _QuadricepsMotionPhase { neutral, raising }

/// Plays a timed exercise video exactly once when the set begins.
class _TimedAssetGuide extends StatefulWidget {
  final _QuadricepsMotionPhase phase;
  final String assetPath;

  const _TimedAssetGuide({
    super.key,
    required this.phase,
    required this.assetPath,
  });

  @override
  State<_TimedAssetGuide> createState() => _TimedAssetGuideState();
}

class _TimedAssetGuideState extends State<_TimedAssetGuide>
    with WidgetsBindingObserver {
  late final VideoPlayerController _videoController;
  bool _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoController = VideoPlayerController.asset(
      widget.assetPath,
    );
    _videoController.initialize().then((_) {
      if (!mounted) return;
      _videoController.setVolume(0);
      _syncPlayback();
      setState(() {});
    }).catchError((Object _) {
      if (mounted) setState(() => _hasLoadError = true);
    });
  }

  @override
  void didUpdateWidget(covariant _TimedAssetGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase &&
        widget.phase == _QuadricepsMotionPhase.raising) {
      _syncPlayback();
    }
  }

  void _syncPlayback() {
    if (!_videoController.value.isInitialized ||
        widget.phase != _QuadricepsMotionPhase.raising) {
      return;
    }
    _videoController
      ..seekTo(Duration.zero)
      ..play();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _videoController.value.isPlaying) {
      _videoController.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: _hasLoadError
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '운동 영상을 불러오지 못했어요.\n앱을 완전히 종료한 뒤 다시 실행해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xff5D6170)),
                ),
              ),
            )
          : !_videoController.value.isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff725AC1)),
            )
          : Center(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            ),
    );
  }
}

/// Reusable motion rig for the two common lower-body moves. The motion is
/// independent from the selected explorer/pet skin, so new profiles only add
/// colours and a pet instead of requiring new exercise artwork.
// ignore: unused_element
class _ExplorerPetMotionGuide extends StatelessWidget {
  final AnimationController controller;
  final FigureAnimation animation;
  final String profileId;

  const _ExplorerPetMotionGuide({
    required this.controller,
    required this.animation,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xff171923),
        borderRadius: BorderRadius.circular(28),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomPaint(
          painter: _ExplorerPetMotionPainter(
            phase: controller.value,
            animation: animation,
            profileId: profileId,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ExplorerPetMotionPainter extends CustomPainter {
  final double phase;
  final FigureAnimation animation;
  final String profileId;

  const _ExplorerPetMotionPainter({
    required this.phase,
    required this.animation,
    required this.profileId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 280, size.height / 330);
    final origin = Offset(
      (size.width - 280 * scale) / 2,
      (size.height - 330 * scale) / 2,
    );
    canvas
      ..save()
      ..translate(origin.dx, origin.dy)
      ..scale(scale);

    final pulse = Curves.easeInOut.transform(phase);
    final skin = _ExplorerMotionSkin.forProfile(profileId);
    final isQuadStretch = animation == FigureAnimation.hipFlexor;
    final floor = Paint()..color = const Color(0xff2A2E3B);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(140, 303), width: 220, height: 25),
      floor,
    );

    _drawExplorer(canvas, skin, pulse, isQuadStretch);
    _drawPet(canvas, skin, pulse, isQuadStretch);
    _drawMotionCue(canvas, pulse, isQuadStretch, skin.accent);
    canvas.restore();
  }

  void _drawExplorer(
    Canvas canvas,
    _ExplorerMotionSkin skin,
    double pulse,
    bool isQuadStretch,
  ) {
    final outline = Paint()
      ..color = const Color(0xff0D1018)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final skinPaint = Paint()..color = const Color(0xffF4C8A6);
    final pants = Paint()..color = skin.pants;
    final jacket = Paint()..color = skin.jacket;
    final trim = Paint()..color = skin.trim;
    final hair = Paint()..color = skin.hair;

    final lean = isQuadStretch ? 0.0 : -6 * pulse;
    final hip = Offset(126 + lean, 188);
    final shoulder = Offset(126 + lean, 112);
    final head = Offset(126 + lean, 75);
    final supportKnee = Offset(112 + lean, 266);
    final supportAnkle = Offset(109 + lean, 300);
    final movingKnee = isQuadStretch
        ? Offset(160 + lean, 246 - 4 * pulse)
        : Offset(164 + lean + 10 * pulse, 267 - 12 * pulse);
    final movingAnkle = isQuadStretch
        ? Offset(185 + lean, 188 + 8 * (1 - pulse))
        : Offset(190 + lean + 22 * pulse, 287 - 28 * pulse);

    // Supporting wall makes both common standing moves easy to read.
    final wall = Paint()..color = const Color(0xff404656);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(27, 82, 10, 215),
        const Radius.circular(6),
      ),
      wall,
    );

    _limb(canvas, hip, supportKnee, 26, pants, outline);
    _limb(canvas, supportKnee, supportAnkle, 23, pants, outline);
    _limb(canvas, hip, movingKnee, 26, pants, outline);
    _limb(canvas, movingKnee, movingAnkle, 23, pants, outline);
    _shoe(canvas, supportAnkle, skin.shoe, outline);
    _shoe(canvas, movingAnkle, skin.shoe, outline);

    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(126 + lean, 149), width: 69, height: 90),
      const Radius.circular(25),
    );
    canvas.drawRRect(torso, jacket);
    canvas.drawRRect(torso, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(126 + lean, 135), width: 67, height: 27),
        const Radius.circular(13),
      ),
      trim,
    );
    canvas.drawLine(
      Offset(126 + lean, 107),
      Offset(126 + lean, 192),
      Paint()
        ..color = const Color(0xffF7F3EA).withValues(alpha: 0.72)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(93 + lean, 177),
      Offset(159 + lean, 177),
      Paint()
        ..color = skin.pants
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    final leftElbow = Offset(76 + lean, 139);
    final leftHand = const Offset(38, 163);
    final rightElbow = isQuadStretch
        ? Offset(177 + lean, 144)
        : Offset(177 + lean, 151);
    final rightHand = isQuadStretch
        ? Offset(movingAnkle.dx + 1, movingAnkle.dy - 4)
        : Offset(167 + lean, 192);
    _limb(canvas, shoulder + const Offset(-25, 0), leftElbow, 18, jacket, outline);
    _limb(canvas, leftElbow, leftHand, 15, jacket, outline);
    _hand(canvas, leftHand, skinPaint, outline);
    _limb(canvas, shoulder + const Offset(25, 0), rightElbow, 18, jacket, outline);
    _limb(canvas, rightElbow, rightHand, 15, jacket, outline);
    _hand(canvas, rightHand, skinPaint, outline);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(head.dx, head.dy + 25), width: 20, height: 28),
        const Radius.circular(8),
      ),
      skinPaint,
    );
    canvas.drawCircle(head, 27, skinPaint);
    canvas.drawCircle(head, 27, outline);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(head.dx, head.dy - 6), width: 56, height: 48),
      math.pi,
      math.pi,
      true,
      hair,
    );
    canvas.drawCircle(Offset(head.dx - 10, head.dy + 2), 3.1, Paint()..color = const Color(0xff20212A));
    canvas.drawCircle(Offset(head.dx + 10, head.dy + 2), 3.1, Paint()..color = const Color(0xff20212A));
    canvas.drawArc(
      Rect.fromCenter(center: Offset(head.dx, head.dy + 11), width: 14, height: 9),
      0.1,
      math.pi - 0.2,
      false,
      Paint()
        ..color = const Color(0xffB55D61)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  void _drawPet(
    Canvas canvas,
    _ExplorerMotionSkin skin,
    double pulse,
    bool isQuadStretch,
  ) {
    final bounce = math.sin(phase * math.pi) * 5;
    final center = Offset(224, 249 - bounce);
    final outline = Paint()
      ..color = const Color(0xff0D1018)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final body = Paint()..color = skin.petBody;
    final face = Paint()..color = skin.petFace;

    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(0, 23), width: 62, height: 75),
      body,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(0, 23), width: 62, height: 75),
      outline,
    );
    _drawPetEars(canvas, center, skin, outline);
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(0, 10), width: 49, height: 40),
      face,
    );

    final eye = Paint()..color = const Color(0xff20212A);
    canvas.drawCircle(center + const Offset(-10, 8), 3.2, eye);
    canvas.drawCircle(center + const Offset(10, 8), 3.2, eye);
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(0, 19), width: 8, height: 5),
      Paint()..color = skin.petNose,
    );
    // Matching explorer jacket: the pet is part of the same animated rig.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(0, 37), width: 54, height: 34),
        const Radius.circular(14),
      ),
      Paint()..color = skin.jacket,
    );
    canvas.drawLine(
      center + const Offset(0, 21),
      center + const Offset(0, 53),
      Paint()
        ..color = skin.trim
        ..strokeWidth = 4,
    );

    final legLift = isQuadStretch ? 16 * pulse : 8 * pulse;
    _petLeg(canvas, center + const Offset(-14, 58), center + Offset(-18, 70 - legLift), body, outline);
    _petLeg(canvas, center + const Offset(14, 58), center + Offset(19 + 10 * pulse, 70 - (isQuadStretch ? legLift : 18 * pulse)), body, outline);
  }

  void _drawPetEars(
    Canvas canvas,
    Offset center,
    _ExplorerMotionSkin skin,
    Paint outline,
  ) {
    if (skin.petKind == _PetKind.fox) {
      final ear = Paint()..color = skin.petBody;
      final left = Path()
        ..moveTo(center.dx - 25, center.dy + 1)
        ..lineTo(center.dx - 28, center.dy - 25)
        ..lineTo(center.dx - 8, center.dy - 10)
        ..close();
      final right = Path()
        ..moveTo(center.dx + 25, center.dy + 1)
        ..lineTo(center.dx + 28, center.dy - 25)
        ..lineTo(center.dx + 8, center.dy - 10)
        ..close();
      canvas
        ..drawPath(left, ear)
        ..drawPath(right, ear)
        ..drawPath(left, outline)
        ..drawPath(right, outline);
      return;
    }
    if (skin.petKind == _PetKind.hedgehog) {
      for (var index = 0; index < 7; index++) {
        final x = center.dx - 27 + index * 9;
        canvas.drawLine(
          Offset(x, center.dy - 3),
          Offset(x - 4, center.dy - 21 - (index.isEven ? 5 : 0)),
          Paint()
            ..color = const Color(0xff855337)
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
      }
      return;
    }
    if (skin.petKind == _PetKind.panda) {
      canvas.drawCircle(center + const Offset(-20, -10), 12, Paint()..color = const Color(0xff20212A));
      canvas.drawCircle(center + const Offset(20, -10), 12, Paint()..color = const Color(0xff20212A));
      canvas.drawOval(Rect.fromCenter(center: center + const Offset(-10, 8), width: 15, height: 11), Paint()..color = const Color(0xff20212A));
      canvas.drawOval(Rect.fromCenter(center: center + const Offset(10, 8), width: 15, height: 11), Paint()..color = const Color(0xff20212A));
      return;
    }
    // Penguin's small crown feathers.
    canvas.drawLine(center + const Offset(-5, -10), center + const Offset(-10, -22), outline);
    canvas.drawLine(center + const Offset(2, -10), center + const Offset(7, -22), outline);
  }

  void _drawMotionCue(
    Canvas canvas,
    double pulse,
    bool isQuadStretch,
    Color color,
  ) {
    final cue = Paint()
      ..color = color.withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rect = isQuadStretch
        ? Rect.fromCenter(
            center: const Offset(177, 226),
            width: 66,
            height: 96,
          )
        : Rect.fromCenter(
            center: const Offset(175, 262),
            width: 88,
            height: 52,
          );
    canvas.drawArc(rect, isQuadStretch ? -1.1 : 3.45, isQuadStretch ? 1.1 : 1.0 + pulse * 0.2, false, cue);
  }

  void _limb(Canvas canvas, Offset from, Offset to, double width, Paint fill, Paint outline) {
    canvas
      ..drawLine(from, to, Paint()
        ..color = outline.color
        ..strokeWidth = width + 4
        ..strokeCap = StrokeCap.round)
      ..drawLine(from, to, Paint()
        ..color = fill.color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round);
  }

  void _shoe(Canvas canvas, Offset ankle, Color color, Paint outline) {
    final shoe = RRect.fromRectAndRadius(
      Rect.fromCenter(center: ankle + const Offset(6, 4), width: 29, height: 14),
      const Radius.circular(7),
    );
    canvas
      ..drawRRect(shoe, Paint()..color = color)
      ..drawRRect(shoe, outline);
  }

  void _hand(Canvas canvas, Offset point, Paint fill, Paint outline) {
    canvas
      ..drawCircle(point, 8, fill)
      ..drawCircle(point, 8, outline);
  }

  void _petLeg(Canvas canvas, Offset from, Offset to, Paint fill, Paint outline) {
    _limb(canvas, from, to, 10, fill, outline);
  }

  @override
  bool shouldRepaint(covariant _ExplorerPetMotionPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.animation != animation ||
      oldDelegate.profileId != profileId;
}

enum _PetKind { fox, hedgehog, penguin, panda }

class _ExplorerMotionSkin {
  final Color jacket;
  final Color trim;
  final Color pants;
  final Color shoe;
  final Color hair;
  final Color accent;
  final Color petBody;
  final Color petFace;
  final Color petNose;
  final _PetKind petKind;

  const _ExplorerMotionSkin({
    required this.jacket,
    required this.trim,
    required this.pants,
    required this.shoe,
    required this.hair,
    required this.accent,
    required this.petBody,
    required this.petFace,
    required this.petNose,
    required this.petKind,
  });

  static _ExplorerMotionSkin forProfile(String profileId) {
    return switch (profileId) {
      'forward' => const _ExplorerMotionSkin(
          jacket: Color(0xff8FCABE), trim: Color(0xffE6F1EC), pants: Color(0xffD8CCB8), shoe: Color(0xff537C78), hair: Color(0xff20242D), accent: Color(0xffE07A3A), petBody: Color(0xffE87531), petFace: Color(0xffFFF1D9), petNose: Color(0xff38241E), petKind: _PetKind.fox),
      'slouch' => const _ExplorerMotionSkin(
          jacket: Color(0xffA87858), trim: Color(0xffF4E5D2), pants: Color(0xff664939), shoe: Color(0xff9A8067), hair: Color(0xff593F33), accent: Color(0xffC18A58), petBody: Color(0xff8A5535), petFace: Color(0xffF2D7B0), petNose: Color(0xff34221D), petKind: _PetKind.hedgehog),
      'tilted' => const _ExplorerMotionSkin(
          jacket: Color(0xff86518A), trim: Color(0xffF4E9DB), pants: Color(0xffE9DECE), shoe: Color(0xff9B7B91), hair: Color(0xff5A3E36), accent: Color(0xff9B6AC9), petBody: Color(0xff20212A), petFace: Color(0xffFFF8EC), petNose: Color(0xff292A30), petKind: _PetKind.panda),
      _ => const _ExplorerMotionSkin(
          jacket: Color(0xff243C67), trim: Color(0xffF2E9D7), pants: Color(0xff24354E), shoe: Color(0xff2D548A), hair: Color(0xff2B1F22), accent: Color(0xff8D6ADC), petBody: Color(0xff202737), petFace: Color(0xffF8F6EC), petNose: Color(0xffF2A62B), petKind: _PetKind.penguin),
    };
  }
}

// ignore: unused_element
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
            errorBuilder: (context, error, stackTrace) => const Icon(
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

CorrectiveRoutine _routineFor(
  String profileId, {
  PandaLeanSide? pandaLeanSide,
}) {
  final routines = switch (profileId) {
    'forward' => _forwardRoutines,
    'slouch' => _slouchRoutines,
    'tilted' => _tiltedRoutines,
    _ => _balancedRoutines,
  };

  final today = DateTime.now();
  final int seed =
      today.year * 10000 +
      today.month * 100 +
      today.day +
      profileId.codeUnits.fold<int>(0, (sum, codeUnit) => sum + codeUnit);
  final routine = routines[seed % routines.length];
  if (profileId != 'tilted' || pandaLeanSide == null) return routine;
  return _applyPandaLateralRecommendation(routine, pandaLeanSide);
}

/// 좌·우 편향을 받았을 때만 해당 쪽 요방형근 이완 영상을 덮어쓴다.
/// 기우뚱 팬더는 옆허리 이완과 기존 고관절 회전 가동성, 두 동작만
/// 한 쌍으로 보여준다.
/// 기존 프로필 화면은 방향을 추측하지 않고 원래 루틴을 유지한다.
CorrectiveRoutine _applyPandaLateralRecommendation(
  CorrectiveRoutine routine,
  PandaLeanSide side,
) {
  if (routine.pairs.length < 2) return routine;

  final sideLabel = side == PandaLeanSide.left ? '우측' : '좌측';
  final videoAssetPath = side == PandaLeanSide.left
      ? 'assets/exercise/quadratus_lumborum_wall_right_pingpong_25s.mp4'
      : 'assets/exercise/quadratus_lumborum_wall_left_pingpong_25s.mp4';
  final quadratusLumborumMove = CorrectiveMove(
    title: '$sideLabel 요방형근 스트레칭',
    target: '$sideLabel 요방형근',
    guide: '벽을 $sideLabel 손으로 짚고, 다리 위치는 그대로 둔 채 $sideLabel 허리를 안쪽으로 부드럽게 늘려요.',
    seconds: 25,
    sets: 2,
    role: MoveRole.release,
    animation: FigureAnimation.hipFlexor,
    videoAssetPath: videoAssetPath,
  );
  final pairs = [...routine.pairs];
  pairs[1] = pairs[1].copyWith(
    title: '$sideLabel 요방형근 이완 → $sideLabel 고관절 회전',
    description: '한쪽으로 굳은 $sideLabel 옆허리를 늘린 뒤, 같은 쪽 고관절 회전 움직임을 부드럽게 되찾아요.',
    release: quadratusLumborumMove,
  );
  return routine.copyWith(pairs: pairs);
}

final _forwardRoutines = <CorrectiveRoutine>[
  CorrectiveRoutine(
    title: 'LHE-A 교정 루틴',
    emoji: '🧭🦊',
    message: '미어켓 탐험가와 쭉뻗 여우를 위한 오늘의 조합이에요.\n허리 과활성을 낮추고 골반을 편하게 지지해요.',
    pairs: [
      CorrectivePair(
        title: '가슴 열기 → 견갑 고정',
        description: '앞쪽의 답답함을 줄이고 어깨를 편하게 뒤로 지지해요.',
        release: CorrectiveMove(
          title: '서서 가슴 열기',
          target: '대흉근·소흉근',
          guide: '깍지 낀 손을 등 뒤로 보내고, 가슴을 편하게 열어주세요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.chestOpen,
          videoAssetPath: 'assets/exercise/pec_stretch_clean_hold20_reverse.mp4',
        ),
        activate: CorrectiveMove(
          title: '벽 없이 견갑 조이기',
          target: '능형근·중부 승모근',
          guide: '팔꿈치를 뒤로 끌어당기듯, 날개뼈를 가볍게 모아 2초 버텨요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.scapularSet,
        ),
      ),
      CorrectivePair(
        title: '장요근 이완 → 둔근 강화',
        description: '고관절 앞쪽을 늘린 뒤, 둔근으로 골반을 안정적으로 지지해요.',
        release: CorrectiveMove(
          title: '반무릎 장요근 스트레칭',
          target: '장요근·대퇴직근',
          guide: '뒤쪽 무릎은 고정하고 앞무릎을 천천히 굽혀, 허리를 꺾지 않고 고관절 앞쪽을 늘려요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.hipFlexor,
          videoAssetPath:
              'assets/exercise/half_kneeling_hip_flexor_pingpong_25s.mp4',
        ),
        activate: CorrectiveMove(
          title: '스탠딩 힙 힌지',
          target: '대둔근·햄스트링',
          guide: '무릎은 살짝 굽히고 엉덩이만 뒤로 보내며, 허리는 중립으로 길게 유지해요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.hipFlexor,
          videoAssetPath:
              'assets/exercise/standing_hip_hinge_pingpong_25s.mp4',
        ),
      ),
    ],
  ),
  CorrectiveRoutine(
    title: 'LHE-A 교정 루틴',
    emoji: '🧭🦊',
    message: '미어켓 탐험가와 쭉뻗 여우를 위한 오늘의 조합이에요.\n갈비뼈와 골반을 편하게 정렬해요.',
    pairs: [
      CorrectivePair(
        title: '등 이완 → 팔꿈치 지지 푸시업 플러스',
        description: '등의 과한 긴장을 낮춘 뒤, 전거근으로 견갑골을 안정적으로 밀어요.',
        release: CorrectiveMove(
          title: '서서 등 길게 늘리기',
          target: '광배근·능형근 주변',
          guide: '두 손을 앞으로 뻗으며 등을 둥글고 길게 늘려주세요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.upperBackReach,
          videoAssetPath:
              'assets/exercise/back_stretch_total25_hold14_88_reverse.mp4',
        ),
        activate: CorrectiveMove(
          title: '팔꿈치 지지 푸시업 플러스',
          target: '전거근·하부 승모근',
          guide: '팔꿈치로 바닥을 밀어 등 윗부분을 넓히되, 허리는 꺾지 않아요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.scapularSet,
          videoAssetPath:
              'assets/exercise/forearm_pushup_plus_pingpong_25s.mp4',
        ),
      ),
      CorrectivePair(
        title: '장요근 이완 → 둔근 강화',
        description: '고관절 앞쪽을 늘린 뒤, 둔근으로 골반을 안정적으로 지지해요.',
        release: CorrectiveMove(
          title: '반무릎 장요근 스트레칭',
          target: '장요근·대퇴직근',
          guide: '뒤쪽 무릎은 고정하고 앞무릎을 천천히 굽혀, 허리를 꺾지 않고 고관절 앞쪽을 늘려요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.hipFlexor,
          videoAssetPath:
              'assets/exercise/half_kneeling_hip_flexor_pingpong_25s.mp4',
        ),
        activate: CorrectiveMove(
          title: '스탠딩 힙 힌지',
          target: '대둔근·햄스트링',
          guide: '무릎은 살짝 굽히고 엉덩이만 뒤로 보내며, 허리는 중립으로 길게 유지해요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.hipFlexor,
          videoAssetPath:
              'assets/exercise/standing_hip_hinge_pingpong_25s.mp4',
        ),
      ),
    ],
  ),
];

final _slouchRoutines = <CorrectiveRoutine>[
  CorrectiveRoutine(
    title: 'SSS-P 교정 루틴',
    emoji: '🐻🦔',
    message: '쉬었음 탐험가와 웅크림 고슴도치를 위한 오늘의 조합이에요.\n굳은 앞쪽을 풀고, 등을 펴는 힘을 깨워요.',
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
          videoAssetPath:
              'assets/exercise/back_stretch_total25_hold14_88_reverse.mp4',
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
      _hedgehogLowerBodyPair,
    ],
  ),
  CorrectiveRoutine(
    title: 'SSS-P 교정 루틴',
    emoji: '🐻🦔',
    message: '쉬었음 탐험가와 웅크림 고슴도치를 위한 오늘의 조합이에요.\n목·어깨 긴장을 낮추고 상체를 세워요.',
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
      _hedgehogLowerBodyPair,
    ],
  ),
];

final _hedgehogLowerBodyPair = CorrectivePair(
  title: '햄스트링 이완 → 장요근 수축',
  description: '골반을 뒤로 당기는 햄스트링 긴장을 낮춘 뒤, 고관절 앞쪽을 편하게 쓰는 감각을 되찾아요.',
  release: CorrectiveMove(
    title: '스탠딩 햄스트링 스트레칭',
    target: '햄스트링',
    guide: '무릎을 과하게 잠그지 말고, 허리를 길게 유지한 채 엉덩이를 뒤로 보내요.',
    seconds: 25,
    sets: 2,
    role: MoveRole.release,
    animation: FigureAnimation.hipFlexor,
    videoAssetPath: 'assets/exercise/standing_hamstring_stretch_pingpong_25s.mp4',
  ),
  activate: CorrectiveMove(
    title: '장요근 운동',
    target: '장요근·대퇴직근',
    guide: '양손으로 벽을 짚고 골반을 중립에 둔 채, 한쪽 무릎을 천천히 들어 올려요.',
    seconds: 25,
    sets: 2,
    role: MoveRole.activate,
    animation: FigureAnimation.hipFlexor,
    videoAssetPath: 'assets/exercise/wall_supported_knee_raise_pingpong_25s.mp4',
  ),
);

final _tiltedRoutines = <CorrectiveRoutine>[
  CorrectiveRoutine(
    title: 'LHE-T 균형 리셋 루틴',
    emoji: '🐼',
    message: '미어켓 탐험가와 기우뚱 팬더를 위한 오늘의 조합이에요.\n허리를 꺾는 힘은 낮추고 골반의 좌우 균형을 되찾아요.',
    pairs: [
      CorrectivePair(
        title: '목 옆 이완 → 턱 당기기',
        description: '한쪽으로 쏠린 목 주변을 풀고, 고개를 편한 중심으로 되돌려요.',
        release: CorrectiveMove(
          title: '목 옆 부드럽게 늘리기',
          target: '목',
          guide: '어깨 힘을 빼고, 머리를 한쪽으로 아주 천천히 기울여 목 옆을 늘려요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.neckRelease,
        ),
        activate: CorrectiveMove(
          title: '서서 턱 당기기',
          target: '목',
          guide: '정면을 보며 턱을 수평으로 살짝 뒤로 당겨 중심을 잡아요.',
          seconds: 20,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.chinTuck,
        ),
      ),
      CorrectivePair(
        title: '이상근 이완 → 둔근 강화',
        description: '엉덩이 깊은 곳의 긴장을 낮춘 뒤, 둔근을 깨워 골반이 한쪽으로 쏠리지 않게 도와요.',
        release: CorrectiveMove(
          title: '의자 이상근 스트레칭',
          target: '이상근·심부 외회전근',
          guide: '한쪽 발목을 반대쪽 무릎 위에 올리고, 등을 길게 유지한 채 무릎을 가볍게 아래로 눌러요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.release,
          animation: FigureAnimation.hipFlexor,
          videoAssetPath:
              'assets/exercise/seated_piriformis_stretch_pingpong_25s.mp4',
        ),
        activate: CorrectiveMove(
          title: '스탠딩 힙 익스텐션',
          target: '둔근',
          guide: '허리를 꺾지 말고 한쪽 다리를 뒤로 작게 뻗어 둔근에 2초 힘을 주세요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.gluteSet,
          videoAssetPath:
              'assets/exercise/glute_extension_total25_reverse_play_x3_ground_hold.mp4',
        ),
      ),
    ],
  ),
];

final _balancedRoutines = <CorrectiveRoutine>[
  CorrectiveRoutine(
    title: 'BPS-N 유지 루틴',
    emoji: '🐧🦦',
    message: '바른자세 탐험가와 중심 펭귄이 함께하는 오늘의 조합이에요.\n가볍게 풀고, 편한 자세를 기억해요.',
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
    message: '바른자세 탐험가와 중심 펭귄이 함께하는 오늘의 조합이에요.\n상체와 골반을 편하게 깨워요.',
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
          videoAssetPath:
              'assets/exercise/back_stretch_total25_hold14_88_reverse.mp4',
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
          videoAssetPath:
              'assets/exercise/rectus_femoris_total25_hold15_5_reverse.mp4',
        ),
        activate: CorrectiveMove(
          title: '스탠딩 힙 익스텐션',
          target: '둔근',
          guide: '허리를 꺾지 말고 한쪽 다리를 뒤로 작게 뻗어 둔근에 2초 힘을 주세요.',
          seconds: 25,
          sets: 2,
          role: MoveRole.activate,
          animation: FigureAnimation.gluteSet,
          videoAssetPath:
              'assets/exercise/glute_extension_total25_reverse_play_x3_ground_hold.mp4',
        ),
      ),
    ],
  ),
];

List<_MoveOption> _stretchMoveOptions(MoveRole role) {
  final pairsByTitle = <String, CorrectivePair>{};
  final routines = [
    ..._forwardRoutines,
    ..._slouchRoutines,
    ..._tiltedRoutines,
    ..._balancedRoutines,
  ];

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
      seconds: 25,
      sets: 2,
      role: MoveRole.activate,
      animation: FigureAnimation.gluteSet,
      videoAssetPath:
          'assets/exercise/glute_extension_total25_reverse_play_x3_ground_hold.mp4',
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
    String? title,
    String? description,
    CorrectiveMove? release,
    CorrectiveMove? activate,
  }) {
    return CorrectivePair(
      title: title ?? this.title,
      description: description ?? this.description,
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
  final String? videoAssetPath;

  const CorrectiveMove({
    required this.title,
    required this.target,
    required this.guide,
    required this.seconds,
    required this.sets,
    required this.role,
    required this.animation,
    this.videoAssetPath,
  });

  /// 같은 종목은 어느 루틴에서 선택되어도 사용자가 만든 실사 가이드를
  /// 우선 사용한다. 개별 루틴의 경로 누락으로 영상이 안 뜨는 일을 막는다.
  String? get resolvedVideoAssetPath {
    if (videoAssetPath != null) return videoAssetPath;
    return switch (title) {
      '목 옆 부드럽게 늘리기' =>
        'assets/exercise/neck_stretch_clean_white_v2.mp4',
      '서서 턱 당기기' =>
        'assets/exercise/chin_tuck_pingpong_pause_white_crop_25s.mp4',
      '서서 가슴 열기' =>
        'assets/exercise/pec_stretch_clean_hold20_reverse.mp4',
      '벽 없이 견갑 조이기' =>
        'assets/exercise/scapular_retraction_pingpong_25s.mp4',
      '서서 Y 팔 들기' =>
        'assets/exercise/standing_y_raise_pingpong_25s.mp4',
      '스탠딩 햄스트링 스트레칭' =>
        'assets/exercise/standing_hamstring_stretch_pingpong_25s.mp4',
      '서서 등 길게 늘리기' =>
        'assets/exercise/back_stretch_total25_hold14_88_reverse.mp4',
      '서서 대퇴직근 스트레칭' =>
        'assets/exercise/rectus_femoris_total25_hold15_5_reverse.mp4',
      '스탠딩 힙 익스텐션' =>
        'assets/exercise/glute_extension_total25_reverse_play_x3_ground_hold.mp4',
      '장요근 운동' =>
        'assets/exercise/wall_supported_knee_raise_pingpong_25s.mp4',
      _ => null,
    };
  }
}
