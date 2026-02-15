import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/services/stats_store.dart';

class TapTargetGame extends StatefulWidget {
  const TapTargetGame({super.key});

  @override
  State<TapTargetGame> createState() => _TapTargetGameState();
}

class _TapTargetGameState extends State<TapTargetGame>
    with TickerProviderStateMixin {
  final Random _random = Random();
  late final AnimationController _timerCtrl;

  int _level = 1;
  int _correct = 0;
  int _errors = 0;
  int _levelScore = 0;
  bool _showStars = false;
  bool _lockInput = false;

  Offset _targetPos = Offset.zero;
  Size _boardSize = Size.zero;
  bool _initialized = false;

  DateTime _startedAt = DateTime.now();
  bool _saved = false;
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _onMiss();
        }
      });
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
    _timerCtrl.dispose();
    super.dispose();
  }

  String _todayKey() {
    final now = DateTime.now();
    final yyyy = now.year.toString().padLeft(4, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Future<void> _saveStatsIfNeeded() async {
    if (_saved) return;
    _saved = true;
    final duration =
        DateTime.now().difference(_startedAt).inSeconds.clamp(1, 999999);
    await StatsStore.instance.addStat(
      StatRecord(
        date: _todayKey(),
        gameKey: 'tap_target',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  double _targetSize(bool isTablet) {
    if (_level == 1) return isTablet ? 140 : 110;
    if (_level == 2) return isTablet ? 120 : 90;
    return isTablet ? 100 : 75;
  }

  Duration _timeLimit() {
    if (_level == 1) return const Duration(milliseconds: 3000);
    if (_level == 2) return const Duration(milliseconds: 2000);
    return const Duration(milliseconds: 1600);
  }

  int _targetGoal() {
    if (_level == 1) return 8;
    if (_level == 2) return 10;
    return 12;
  }

  void _startLevel() {
    _levelScore = 0;
    _moveTarget();
  }

  void _ensureStarted() {
    if (_initialized) return;
    if (!mounted) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startLevel();
    });
  }

  void _moveTarget() {
    if (_boardSize == Size.zero) return;
    final isTablet = _boardSize.width >= 900;
    final size = _targetSize(isTablet);
    final margin = 16.0;
    final maxX = _boardSize.width - size - margin;
    final maxY = _boardSize.height - size - margin;
    final dx = margin + _random.nextDouble() * max(0, maxX - margin);
    final dy = margin + _random.nextDouble() * max(0, maxY - margin);
    setState(() => _targetPos = Offset(dx, dy));

    _timerCtrl.stop();
    _timerCtrl.reset();
    _timerCtrl.duration = _timeLimit();
    _timerCtrl.forward();
  }

  Future<void> _onHit() async {
    if (_lockInput) return;
    _hasPlayed = true;
    _correct += 1;
    _levelScore += 1;
    setState(() => _showStars = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _showStars = false);

    if (_levelScore >= _targetGoal()) {
      await _onLevelComplete();
      return;
    }
    _moveTarget();
  }

  void _onMiss() {
    if (_lockInput) return;
    _hasPlayed = true;
    _errors += 1;
    _moveTarget();
  }

  Future<void> _onLevelComplete() async {
    _lockInput = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/json/stars.json',
                  width: 160,
                  height: 160,
                  repeat: false,
                ),
                const SizedBox(height: 8),
                const Text(
                  'أحسنت!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E212D),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_level < 3 ? 'التالي' : 'إعادة اللعب'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (_level < 3) {
      _level += 1;
      _lockInput = false;
      _startLevel();
      return;
    }
    await _saveStatsIfNeeded();
    _level = 1;
    _lockInput = false;
    _correct = 0;
    _errors = 0;
    _startedAt = DateTime.now();
    _saved = false;
    _startLevel();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 900;
    const backgroundPath = 'assets/gamenumbers/bg.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(backgroundPath, fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 46),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _TopBar(
                    level: _level,
                    score: _correct,
                    miss: _errors,
                    timer: _timerCtrl,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: isTablet ? size.width * 0.7 : size.width * 0.9,
                      height:
                          isTablet ? size.height * 0.65 : size.height * 0.55,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          _boardSize = Size(c.maxWidth, c.maxHeight);
                          _ensureStarted();
                          final size = _targetSize(isTablet);
                          return Stack(
                            children: [
                              AnimatedPositioned(
                                duration: _level == 3
                                    ? const Duration(milliseconds: 1200)
                                    : Duration.zero,
                                left: _targetPos.dx,
                                top: _targetPos.dy,
                                child: GestureDetector(
                                  onTap: _onHit,
                                  child: Image.asset(
                                    'assets/games/target_star.png',
                                    width: size,
                                    height: size,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              if (_showStars)
                                Center(
                                  child: Lottie.asset(
                                    'assets/json/stars.json',
                                    width: isTablet ? 160 : 130,
                                    height: isTablet ? 160 : 130,
                                    repeat: false,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int level;
  final int score;
  final int miss;
  final AnimationController timer;

  const _TopBar({
    required this.level,
    required this.score,
    required this.miss,
    required this.timer,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _chip('المستوى $level', isTablet),
            const SizedBox(width: 8),
            _chip('النقاط $score', isTablet),
            const SizedBox(width: 8),
            _chip('الأخطاء $miss', isTablet),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: AnimatedBuilder(
            animation: timer,
            builder: (context, _) {
              return LinearProgressIndicator(
                value: 1 - timer.value,
                minHeight: isTablet ? 8 : 6,
                backgroundColor: Colors.white.withOpacity(0.4),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF4DA3FF)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String text, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTablet ? 12 : 10,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1E212D),
        ),
      ),
    );
  }
}
