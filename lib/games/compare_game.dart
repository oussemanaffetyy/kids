import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/services/stats_store.dart';

enum _CompareMode { size, quantity, number }

const _fruitItems = [
  'assets/games/VegetablesetFruits/Fruits/Fruits-Apple.png',
  'assets/games/VegetablesetFruits/Fruits/Fruits-Banana.png',
  'assets/games/VegetablesetFruits/Fruits/Fruits-BlackBerry.png',
  'assets/games/VegetablesetFruits/Fruits/Fruits-Cherry.png',
  'assets/games/VegetablesetFruits/Fruits/Fruits-Grapes.png',
  'assets/games/VegetablesetFruits/Fruits/Fruits-Orange.png',
  'assets/games/VegetablesetFruits/Fruits/Fruits-Pear.png',
  'assets/games/VegetablesetFruits/Fruits/Fruits-Pineapple.png',
  'assets/games/VegetablesetFruits/Fruits/Fruits-Pomegranate.png',
  'assets/games/VegetablesetFruits/Fruits/Fruits-Strawberry.png',
  'assets/games/VegetablesetFruits/Fruits/Fruits-WaterMelon.png',
];

const _numberColors = [
  Color(0xFF4DA3FF),
  Color(0xFF5AC46A),
  Color(0xFFF6C453),
  Color(0xFFF15B5B),
  Color(0xFF8E7BFF),
  Color(0xFFFF8C42),
  Color(0xFF3DD6D0),
  Color(0xFFB76BFF),
  Color(0xFF6BCB77),
  Color(0xFFFF6FB1),
];

class CompareGame extends StatefulWidget {
  const CompareGame({super.key});

  @override
  State<CompareGame> createState() => _CompareGameState();
}

class _CompareGameState extends State<CompareGame>
    with TickerProviderStateMixin {
  final Random _random = Random();

  _CompareQuestion? _question;
  int _level = 1;
  int _correctStreak = 0;
  int _levelStars = 0;
  bool _showStars = false;
  bool _lockInput = false;
  String? _feedback;
  int? _shakingSide;

  int _errors = 0;
  int _correct = 0;
  DateTime _startedAt = DateTime.now();
  bool _saved = false;
  bool _hasPlayed = false;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _resetGame();
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _resetGame() {
    _level = 1;
    _correctStreak = 0;
    _levelStars = 0;
    _errors = 0;
    _correct = 0;
    _saved = false;
    _hasPlayed = false;
    _startedAt = DateTime.now();
    _nextQuestion();
  }

  void _nextQuestion() {
    _lockInput = false;
    _showStars = false;
    _feedback = null;
    _shakingSide = null;
    _question = _buildQuestion();
    setState(() {});
  }

  _CompareQuestion _buildQuestion() {
    if (_level == 1) {
      final fruit = _fruitItems[_random.nextInt(_fruitItems.length)];
      final leftScale = _randomScale();
      double rightScale = _randomScale();
      while ((leftScale - rightScale).abs() < 0.22) {
        rightScale = _randomScale();
      }
      return _CompareQuestion(
        mode: _CompareMode.size,
        leftValue: 0,
        rightValue: 0,
        leftScale: leftScale,
        rightScale: rightScale,
        fruitPath: fruit,
      );
    }
    if (_level == 2) {
      final fruit = _fruitItems[_random.nextInt(_fruitItems.length)];
      int left = _random.nextInt(6) + 1;
      int right = _random.nextInt(6) + 1;
      while (left == right) {
        right = _random.nextInt(6) + 1;
      }
      return _CompareQuestion(
        mode: _CompareMode.quantity,
        leftValue: left,
        rightValue: right,
        leftScale: 1,
        rightScale: 1,
        fruitPath: fruit,
      );
    }
    int left = _random.nextInt(10) + 1;
    int right = _random.nextInt(10) + 1;
    while (left == right) {
      right = _random.nextInt(10) + 1;
    }
    return _CompareQuestion(
      mode: _CompareMode.number,
      leftValue: left,
      rightValue: right,
      leftScale: 1,
      rightScale: 1,
      fruitPath: null,
    );
  }

  double _randomScale() {
    return 0.7 + _random.nextDouble() * 0.6; // 0.7 - 1.3
  }

  String _promptText() {
    if (_level == 1) return 'اختر الأكبر';
    if (_level == 2) return 'اختر الأكثر';
    return 'اختر العدد الأكبر';
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
        gameKey: 'compare',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  Future<void> _onAnswer(bool isLeft) async {
    if (_lockInput || _question == null) return;
    _hasPlayed = true;
    _lockInput = true;
    final isCorrect = isLeft == _question!.leftIsCorrect;

    if (isCorrect) {
      _correct += 1;
      _feedback = 'أحسنت!';
      setState(() => _showStars = true);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _showStars = false);

      _correctStreak += 1;
      if (_correctStreak >= 5) {
        if (_level < 3) {
          _levelStars = _level;
          await _showLevelDialog();
          if (!mounted) return;
          _level += 1;
          _correctStreak = 0;
          _nextQuestion();
          return;
        }
        await _saveStatsIfNeeded();
        await _showWinDialog();
        return;
      }
      _nextQuestion();
    } else {
      _errors += 1;
      _correctStreak = 0;
      _feedback = 'جرّب مرة أخرى';
      _shakingSide = isLeft ? 0 : 1;
      _shakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _lockInput = false;
      setState(() => _shakingSide = null);
    }
  }

  Future<void> _showLevelDialog() async {
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
                  child: const Text('التالي'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showWinDialog() async {
    if (!mounted) return;
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Lottie.asset(
                      'assets/json/stars.json',
                      width: 160,
                      height: 160,
                      repeat: false,
                    ),
                    Lottie.asset(
                      'assets/json/win.json',
                      width: 110,
                      height: 110,
                      repeat: true,
                    ),
                  ],
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
                  child: const Text('إعادة اللعب'),
                ),
              ],
            ),
          ),
        );
      },
    );
    _resetGame();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 900;
    final cardWidth =
        (isTablet ? size.width * 0.55 : size.width * 0.9).clamp(260.0, 620.0);
    final tileSize =
        (isTablet ? cardWidth * 0.32 : cardWidth * 0.4).clamp(140.0, 220.0);
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
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: List.generate(
                    _levelStars,
                    (index) => Image.asset(
                      'assets/images/level.png',
                      width: isTablet ? 44 : 34,
                      height: isTablet ? 44 : 34,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _promptText(),
                            style: TextStyle(
                              fontSize: isTablet ? 22 : 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E212D),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AnimatedBuilder(
                            animation: _shakeAnim,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  _shakingSide == null ? 0 : _shakeAnim.value,
                                  0,
                                ),
                                child: child,
                              );
                            },
                            child: Wrap(
                              spacing: isTablet ? 26 : 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildOption(true, tileSize, isTablet),
                                _buildOption(false, tileSize, isTablet),
                              ],
                            ),
                          ),
                          if (_feedback != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _feedback!,
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E212D),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          if (_showStars)
            Center(
              child: Lottie.asset(
                'assets/json/stars.json',
                width: isTablet ? 180 : 140,
                height: isTablet ? 180 : 140,
                repeat: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOption(bool isLeft, double tileSize, bool isTablet) {
    final question = _question;
    if (question == null) {
      return const SizedBox.shrink();
    }
    late final Widget content;
    switch (question.mode) {
      case _CompareMode.size:
        content = _buildSizeTile(
          question.fruitPath!,
          isLeft ? question.leftScale : question.rightScale,
          tileSize,
        );
        break;
      case _CompareMode.quantity:
        content = _buildQuantityTile(
          question.fruitPath!,
          isLeft ? question.leftValue : question.rightValue,
          tileSize,
        );
        break;
      case _CompareMode.number:
        content = _buildNumberTile(
          isLeft ? question.leftValue : question.rightValue,
          tileSize,
          isTablet,
        );
        break;
    }

    return GestureDetector(
      onTap: () => _onAnswer(isLeft),
      child: Container(
        width: tileSize,
        height: tileSize,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(child: content),
      ),
    );
  }

  Widget _buildSizeTile(String fruitPath, double scale, double tileSize) {
    final size = tileSize * 0.6 * scale;
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        fruitPath,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildQuantityTile(String fruitPath, int count, double tileSize) {
    final itemSize = (tileSize * 0.28).clamp(24.0, 40.0);
    return SizedBox(
      width: tileSize * 0.8,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: itemSize * 0.15,
        runSpacing: itemSize * 0.15,
        children: List.generate(
          count,
          (index) => Image.asset(
            fruitPath,
            width: itemSize,
            height: itemSize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberTile(int number, double tileSize, bool isTablet) {
    final color = _numberColors[(number - 1) % _numberColors.length];
    return Text(
      number.toString(),
      style: TextStyle(
        fontSize: isTablet ? 64 : 52,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _CompareQuestion {
  final _CompareMode mode;
  final int leftValue;
  final int rightValue;
  final double leftScale;
  final double rightScale;
  final String? fruitPath;

  const _CompareQuestion({
    required this.mode,
    required this.leftValue,
    required this.rightValue,
    required this.leftScale,
    required this.rightScale,
    required this.fruitPath,
  });

  bool get leftIsCorrect {
    switch (mode) {
      case _CompareMode.size:
        return leftScale > rightScale;
      case _CompareMode.quantity:
        return leftValue > rightValue;
      case _CompareMode.number:
        return leftValue > rightValue;
    }
  }
}
