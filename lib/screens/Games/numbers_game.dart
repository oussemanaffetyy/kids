import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/services/stats_store.dart';

class NumbersGame extends StatefulWidget {
  const NumbersGame({super.key});

  @override
  State<NumbersGame> createState() => _NumbersGameState();
}

class _NumbersGameState extends State<NumbersGame>
    with TickerProviderStateMixin {
  final AudioPlayer _tapPlayer = AudioPlayer();
  final Random _random = Random();

  int _stage = 1; // 1..3 (difficulty)
  int _numberIndex = 0; // 0..8 => numbers 1..9
  int _levelStars = 0;
  String _objectPath = '';
  List<int> _options = [];
  int? _selected;
  bool _showStars = false;
  bool _lockInput = false;
  bool _isCorrectSelection = false;
  String _lastOptionsKey = '';
  String _lastObjectPath = '';
  int _errors = 0;
  int _correct = 0;
  DateTime _startedAt = DateTime.now();
  bool _saved = false;
  bool _hasPlayed = false;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  late final AnimationController _floatCtrl;

  final List<String> _objects = const [
    'assets/gamenumbers/objects/apple.png',
    'assets/gamenumbers/objects/ball.png',
    'assets/gamenumbers/objects/cup.png',
    'assets/gamenumbers/objects/fraise.png',
    'assets/gamenumbers/objects/star.png',
  ];

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
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _resetLevels();
    _startLevel();
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
    _tapPlayer.dispose();
    _shakeCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _resetLevels() {
    _stage = 1;
    _numberIndex = 0;
    _levelStars = 0;
    _errors = 0;
    _correct = 0;
    _saved = false;
    _hasPlayed = false;
    _startedAt = DateTime.now();
  }

  int get _level => _numberIndex + 1;

  void _startLevel() {
    _selected = null;
    _showStars = false;
    _lockInput = false;
    _isCorrectSelection = false;
    if (_objects.isNotEmpty) {
      var next = _objects[_random.nextInt(_objects.length)];
      if (_objects.length > 1) {
        while (next == _objectPath) {
          next = _objects[_random.nextInt(_objects.length)];
        }
      }
      _objectPath = next;
      _lastObjectPath = _objectPath;
    }
    final wrongCount = _stage == 1 ? 1 : (_stage == 2 ? 2 : 3);
    var options = _buildOptions(_level, wrongCount);
    var key = options.join('-');
    if (_lastOptionsKey.isNotEmpty) {
      var guard = 0;
      while (key == _lastOptionsKey && guard < 5) {
        options = _buildOptions(_level, wrongCount);
        key = options.join('-');
        guard += 1;
      }
    }
    _options = options;
    _lastOptionsKey = key;
    setState(() {});
  }

  List<int> _buildOptions(int correct, int wrongCount) {
    final set = <int>{correct};
    while (set.length < (wrongCount + 1)) {
      final n = _random.nextInt(9) + 1;
      if (n != correct) set.add(n);
    }
    final list = set.toList()..shuffle(_random);
    return list;
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
        gameKey: 'numbers',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  Future<void> _onOptionTap(int value) async {
    if (_lockInput) return;
    _lockInput = true;
    _hasPlayed = true;
    await _tapPlayer.play(AssetSource('voices/tap_click.mp3'));

    if (value == _level) {
      setState(() {
        _selected = value;
        _showStars = true;
        _isCorrectSelection = true;
        _correct += 1;
      });

      await _tapPlayer.play(AssetSource('voices/winner.mp3'));
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _showStars = false);

      if (_stage >= 3 && _numberIndex >= 8) {
        await _saveStatsIfNeeded();
        await _showWinDialog();
        return;
      }

      if (_numberIndex >= 8) {
        _numberIndex = 0;
        if (_stage < 3) {
          _stage += 1;
          _levelStars = _stage - 1;
        }
      } else {
        _numberIndex += 1;
      }
      _startLevel();
      _lockInput = false;
    } else {
      await _tapPlayer.play(AssetSource('voices/wrong.mp3'));
      _errors += 1;
      _selected = value;
      _isCorrectSelection = false;
      _shakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() {
        _selected = null;
        _isCorrectSelection = false;
      });
      _lockInput = false;
    }
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
    _resetLevels();
    _startLevel();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    final isTablet = shortest >= 900;
    final slotGap = isTablet ? 16.0 : 8.0;
    final optionSpacing = isTablet ? 14.0 : 8.0;
    final backgroundPath = 'assets/gamenumbers/bg.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: List.generate(
                  _levelStars,
                  (index) => Image.asset(
                    'assets/images/level.png',
                    width: isTablet ? 46 : 36,
                    height: isTablet ? 46 : 36,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableH = constraints.maxHeight;
                final availableW = constraints.maxWidth;
                final isLandscape = size.width > size.height;
                final optionSize = (shortest * (isTablet ? 0.16 : 0.16)).clamp(
                  isTablet ? 110.0 : 60.0,
                  isTablet ? 140.0 : 84.0,
                );
                final bottomGap = isTablet ? 18.0 : 6.0;
                final optionRows = _options.length <= 2 ? 1 : 2;
                final optionAreaH = (optionSize * optionRows) +
                    (optionRows - 1) * (isTablet ? 12.0 : 8.0);
                const eqFactor = 0.30;
                final useRow = isTablet || isLandscape;
                final rowGap = isTablet ? 16.0 : 10.0;

                final slotSize = useRow
                    ? min(
                        (availableW - rowGap * 2) / 2.55,
                        (availableH - optionAreaH - bottomGap),
                      ).clamp(
                        isTablet ? 260.0 : 150.0, isTablet ? 380.0 : 220.0)
                    : ((availableH - optionAreaH - bottomGap - slotGap * 2) /
                            (2 + eqFactor))
                        .clamp(120.0, 200.0);

                return Column(
                  mainAxisAlignment: isTablet
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 46),
                    SizedBox(height: isTablet ? 8 : 4),
                    if (useRow)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Slot(
                            size: slotSize,
                            child: _ObjectsGrid(
                              count: _level,
                              imagePath: _objectPath,
                              floatCtrl: _floatCtrl,
                            ),
                          ),
                          SizedBox(width: rowGap),
                          _Slot(
                            size: slotSize * 0.55,
                            child: const Center(
                              child: Text(
                                '=',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E212D),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: rowGap),
                          _Slot(
                            size: slotSize,
                            child: _AnswerSlot(
                              selected: _selected,
                              showStars: _showStars,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _Slot(
                            size: slotSize,
                            child: _ObjectsGrid(
                              count: _level,
                              imagePath: _objectPath,
                              floatCtrl: _floatCtrl,
                            ),
                          ),
                          SizedBox(height: slotGap),
                          _Slot(
                            size: slotSize * 0.30,
                            child: const Center(
                              child: Text(
                                '=',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E212D),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: slotGap),
                          _Slot(
                            size: slotSize,
                            child: _AnswerSlot(
                              selected: _selected,
                              showStars: _showStars,
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: bottomGap),
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnim.value, 0),
                          child: child,
                        );
                      },
                      child: Wrap(
                        spacing: optionSpacing,
                        runSpacing: isTablet ? 12 : 8,
                        alignment: WrapAlignment.center,
                        children: _options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final n = entry.value;
                          return _NumberOption(
                            number: n,
                            onTap: () => _onOptionTap(n),
                            floatCtrl: _floatCtrl,
                            floatIndex: index,
                            isSelected: _selected == n,
                            isCorrect: _selected == n && _isCorrectSelection,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final double size;
  final Widget child;

  const _Slot({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/gamenumbers/card_slot.png',
              fit: BoxFit.contain,
            ),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}

class _ObjectsGrid extends StatelessWidget {
  final int count;
  final String imagePath;
  final AnimationController floatCtrl;

  const _ObjectsGrid({
    required this.count,
    required this.imagePath,
    required this.floatCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridSize = constraints.biggest.shortestSide * 0.88;
        final itemSize = gridSize / 3;
        return SizedBox(
          width: gridSize,
          height: gridSize,
          child: AnimatedBuilder(
            animation: floatCtrl,
            builder: (context, child) {
              return Wrap(
                spacing: 0,
                runSpacing: 0,
                children: List.generate(count, (index) {
                  final t = floatCtrl.value * 2 * pi;
                  final dx = sin(t + index) * 1.6;
                  final dy = cos(t + index * 0.7) * 1.6;
                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: SizedBox(
                      width: itemSize,
                      height: itemSize,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }
}

class _AnswerSlot extends StatelessWidget {
  final int? selected;
  final bool showStars;

  const _AnswerSlot({required this.selected, required this.showStars});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final base = constraints.biggest.shortestSide;
        final numberSize = (base * 0.55).clamp(70.0, 120.0);
        final starsSize = (base * 0.7).clamp(90.0, 150.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            if (selected != null)
              Image.asset(
                'assets/gamenumbers/numbers/${selected!}.png',
                width: numberSize,
                height: numberSize,
                fit: BoxFit.contain,
              ),
            if (showStars)
              Lottie.asset(
                'assets/json/stars.json',
                width: starsSize,
                height: starsSize,
                repeat: false,
              ),
          ],
        );
      },
    );
  }
}

class _NumberOption extends StatefulWidget {
  final int number;
  final VoidCallback onTap;
  final AnimationController floatCtrl;
  final int floatIndex;
  final bool isSelected;
  final bool isCorrect;

  const _NumberOption({
    required this.number,
    required this.onTap,
    required this.floatCtrl,
    required this.floatIndex,
    required this.isSelected,
    required this.isCorrect,
  });

  @override
  State<_NumberOption> createState() => _NumberOptionState();
}

class _NumberOptionState extends State<_NumberOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortest >= 900;
    final optionSize = (shortest * (isTablet ? 0.16 : 0.16))
        .clamp(isTablet ? 110.0 : 60.0, isTablet ? 140.0 : 84.0);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: widget.floatCtrl,
        builder: (context, child) {
          final t = widget.floatCtrl.value * 2 * pi;
          final dx = sin(t + widget.floatIndex) * 2.2;
          final dy = cos(t + widget.floatIndex * 0.9) * 2.2;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: _pressed ? 0.95 : 1,
              child: child,
            ),
          );
        },
        child: SizedBox(
          width: optionSize,
          height: optionSize,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: widget.isSelected
                  ? Border.all(
                      color: widget.isCorrect
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE53935),
                      width: 3,
                    )
                  : null,
            ),
            child: Image.asset(
              'assets/gamenumbers/numbers/${widget.number}.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
