import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/services/stats_store.dart';
import 'package:project_v1/services/tts_helper.dart';

class ListenNameGame extends StatefulWidget {
  const ListenNameGame({super.key});

  @override
  State<ListenNameGame> createState() => _ListenNameGameState();
}

class _ListenNameGameState extends State<ListenNameGame>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final Random _random = Random();

  int _questionIndex = 0;
  List<int> _questionOrder = [];
  _ListenItem? _current;
  List<String> _options = [];
  String? _selected;
  bool _showStars = false;
  bool _lockInput = false;

  int _level = 1;
  int _correctStreak = 0;
  int _levelStars = 0;
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

    Future<void>(() async {
      await TtsHelper.configureArabic(
        _tts,
        pitch: 1.0,
        volume: 0.8,
        speechRate: 0.45,
      );
    });

    _resetQuiz();
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
    _shakeCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  void _resetQuiz() {
    _questionOrder = List.generate(_listenItems.length, (i) => i)
      ..shuffle(_random);
    _questionIndex = 0;
    _level = 1;
    _correctStreak = 0;
    _levelStars = 0;
    _errors = 0;
    _correct = 0;
    _saved = false;
    _hasPlayed = false;
    _startedAt = DateTime.now();
    _startQuestion();
  }

  void _startQuestion() {
    _selected = null;
    _showStars = false;
    _lockInput = false;
    final idx = _questionOrder[_questionIndex];
    _current = _listenItems[idx];
    final wrongCount = _level == 1 ? 1 : (_level == 2 ? 2 : 3);
    _options = _buildOptions(_current!.word, wrongCount);
    setState(() {});
    _speakPrompt();
  }

  List<String> _buildOptions(String correct, int wrongCount) {
    final set = <String>{correct};
    while (set.length < (wrongCount + 1)) {
      final word = _listenItems[_random.nextInt(_listenItems.length)].word;
      if (word != correct) set.add(word);
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
        gameKey: 'listen_name',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  Future<void> _speakPrompt() async {
    if (_current == null) return;
    await TtsHelper.speak(_tts, _current!.word);
  }

  Future<void> _onOptionTap(String word) async {
    if (_lockInput) return;
    _lockInput = true;
    _hasPlayed = true;

    if (_current == null) return;
    if (word == _current!.word) {
      setState(() {
        _selected = word;
        _showStars = true;
        _correct += 1;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _showStars = false);

      _correctStreak += 1;
      if (_correctStreak >= 5 && _level < 3) {
        _level += 1;
        _correctStreak = 0;
        _levelStars = _level - 1;
      }

      _questionIndex += 1;
      if (_questionIndex >= _listenItems.length) {
        await _saveStatsIfNeeded();
        await _showWinDialog();
        return;
      }
      _startQuestion();
    } else {
      _selected = word;
      _errors += 1;
      _shakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _selected = null);
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
    _resetQuiz();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final isCompactPhone = !isTablet && size.height < 720;
    final cardWidth = (isTablet
            ? size.width * 0.36
            : size.width * (isCompactPhone ? 0.74 : 0.78))
        .clamp(190.0, 420.0);
    const backgroundPath = 'assets/gamenumbers/bg.png';
    final cardPadding = isTablet ? 16.0 : (isCompactPhone ? 8.0 : 10.0);
    final topGap = isTablet ? 46.0 : (isCompactPhone ? 34.0 : 46.0);
    final betweenGap = isTablet ? 12.0 : (isCompactPhone ? 6.0 : 8.0);
    final bottomGap = isTablet ? 24.0 : (isCompactPhone ? 12.0 : 20.0);
    final optionWidth = isTablet ? 140.0 : (isCompactPhone ? 100.0 : 108.0);
    final optionHeight = isTablet ? 60.0 : (isCompactPhone ? 48.0 : 52.0);
    final optionFont = isTablet ? 18.0 : (isCompactPhone ? 16.0 : 18.0);

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
            top: MediaQuery.of(context).padding.top + 6,
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
                    width: isTablet ? 44 : 34,
                    height: isTablet ? 44 : 34,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: topGap),
                Expanded(
                  child: Center(
                    child: Container(
                      width: cardWidth,
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxAvatar = (constraints.biggest.shortestSide *
                                  (isTablet
                                      ? 0.78
                                      : (isCompactPhone ? 0.62 : 0.68)))
                              .clamp(
                            isTablet ? 140.0 : (isCompactPhone ? 98.0 : 110.0),
                            isTablet ? 220.0 : (isCompactPhone ? 165.0 : 180.0),
                          );
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_current != null)
                                GestureDetector(
                                  onTap: _speakPrompt,
                                  child: Image.asset(
                                    _current!.imagePath,
                                    width: maxAvatar,
                                    height: maxAvatar,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              SizedBox(
                                  height:
                                      isTablet ? 12 : (isCompactPhone ? 4 : 6)),
                              IconButton(
                                onPressed: _speakPrompt,
                                icon: const Icon(Icons.volume_up),
                                iconSize: isTablet ? 28 : 22,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: betweenGap),
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    );
                  },
                  child: Wrap(
                    spacing: isTablet ? 16 : (isCompactPhone ? 8 : 10),
                    runSpacing: isTablet ? 12 : (isCompactPhone ? 6 : 8),
                    alignment: WrapAlignment.center,
                    children: _options.map((word) {
                      final isSelected = _selected == word;
                      return GestureDetector(
                        onTap: () => _onOptionTap(word),
                        child: SizedBox(
                          width: optionWidth,
                          height: optionHeight,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: optionWidth,
                                height: optionHeight,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    word,
                                    style: TextStyle(
                                      fontSize: optionFont,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E212D),
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected && _showStars)
                                IgnorePointer(
                                  child: Lottie.asset(
                                    'assets/json/stars.json',
                                    width: optionWidth,
                                    height: optionHeight,
                                    repeat: false,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: bottomGap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListenItem {
  final String word;
  final String imagePath;
  final String category;

  const _ListenItem({
    required this.word,
    required this.imagePath,
    required this.category,
  });
}

const _listenItems = [
  _ListenItem(
    word: 'قط',
    imagePath: 'assets/animals/cat.png',
    category: 'animals',
  ),
  _ListenItem(
    word: 'دجاجة',
    imagePath: 'assets/animals/chicken.png',
    category: 'animals',
  ),
  _ListenItem(
    word: 'بقرة',
    imagePath: 'assets/animals/cow.png',
    category: 'animals',
  ),
  _ListenItem(
    word: 'كلب',
    imagePath: 'assets/animals/dog.png',
    category: 'animals',
  ),
  _ListenItem(
    word: 'بطة',
    imagePath: 'assets/animals/duck.png',
    category: 'animals',
  ),
  _ListenItem(
    word: 'ضفدع',
    imagePath: 'assets/animals/frog.png',
    category: 'animals',
  ),
  _ListenItem(
    word: 'ماعز',
    imagePath: 'assets/animals/goat.png',
    category: 'animals',
  ),
  _ListenItem(
    word: 'حصان',
    imagePath: 'assets/animals/horse.png',
    category: 'animals',
  ),
  _ListenItem(
    word: 'أسد',
    imagePath: 'assets/animals/leo.png',
    category: 'animals',
  ),
  _ListenItem(
    word: 'فأر',
    imagePath: 'assets/animals/mouse.png',
    category: 'animals',
  ),
  _ListenItem(
    word: 'الأبيض',
    imagePath: 'assets/couleurs/الأبيض.png',
    category: 'colors',
  ),
  _ListenItem(
    word: 'الأحمر',
    imagePath: 'assets/couleurs/الأحمر.png',
    category: 'colors',
  ),
  _ListenItem(
    word: 'الأخضر',
    imagePath: 'assets/couleurs/الأخضر.png',
    category: 'colors',
  ),
  _ListenItem(
    word: 'الأزرق',
    imagePath: 'assets/couleurs/الأزرق.png',
    category: 'colors',
  ),
  _ListenItem(
    word: 'الأسود',
    imagePath: 'assets/couleurs/الأسود.png',
    category: 'colors',
  ),
  _ListenItem(
    word: 'الأصفر',
    imagePath: 'assets/couleurs/الأصفر.png',
    category: 'colors',
  ),
  _ListenItem(
    word: 'البرتقالي',
    imagePath: 'assets/couleurs/البرتقالي.png',
    category: 'colors',
  ),
  _ListenItem(
    word: 'البنفسجي',
    imagePath: 'assets/couleurs/البنفسجي.png',
    category: 'colors',
  ),
  _ListenItem(
    word: 'البني',
    imagePath: 'assets/couleurs/البني.png',
    category: 'colors',
  ),
  _ListenItem(
    word: 'الوردي',
    imagePath: 'assets/couleurs/الوردي.png',
    category: 'colors',
  ),
];
