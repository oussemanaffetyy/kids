import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/services/stats_store.dart';
import 'package:project_v1/services/tts_helper.dart';

class EmotionGame extends StatefulWidget {
  const EmotionGame({super.key});

  @override
  State<EmotionGame> createState() => _EmotionGameState();
}

class _EmotionGameState extends State<EmotionGame>
    with TickerProviderStateMixin {
  final Random _random = Random();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  _EmotionItem? _current;
  List<_EmotionItem> _options = [];
  List<_EmotionItem> _order = [];
  int _orderIndex = 0;
  int _level = 1;
  int _correctStreak = 0;
  int _levelStars = 0;
  bool _showStars = false;
  bool _lockInput = false;

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

    _resetGame();
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
    _sfxPlayer.dispose();
    _tts.stop();
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
    _order = [..._emotions]..shuffle(_random);
    _orderIndex = 0;
    _startQuestion();
  }

  void _startQuestion() {
    _lockInput = false;
    _showStars = false;
    if (_order.isEmpty || _orderIndex >= _order.length) {
      _order = [..._emotions]..shuffle(_random);
      _orderIndex = 0;
    }
    _current = _order[_orderIndex];
    _orderIndex += 1;
    final optionCount = _level == 1 ? 2 : (_level == 2 ? 3 : 4);
    _options = _buildOptions(optionCount);
    setState(() {});
    _speakCurrentEmotion();
  }

  Future<void> _speakCurrentEmotion() async {
    if (_current == null) return;
    await TtsHelper.speak(_tts, _current!.label);
  }

  List<_EmotionItem> _buildOptions(int count) {
    final pool = [..._emotions]..shuffle(_random);
    final options = <_EmotionItem>[_current!];
    for (final item in pool) {
      if (options.length >= count) break;
      if (item == _current) continue;
      options.add(item);
    }
    options.shuffle(_random);
    return options;
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
        gameKey: 'emotions',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  Future<void> _onAnswer(_EmotionItem item) async {
    if (_lockInput) return;
    _hasPlayed = true;
    _lockInput = true;

    final isCorrect = item == _current;
    if (isCorrect) {
      _correct += 1;
      _sfxPlayer.play(AssetSource('voices/correct.mp3'));
      setState(() => _showStars = true);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _showStars = false);

      _correctStreak += 1;
      if (_correctStreak >= 5) {
        if (_level < 3) {
          _level += 1;
          _levelStars = _level - 1;
          _correctStreak = 0;
          _startQuestion();
          return;
        }
        await _saveStatsIfNeeded();
        await _showWinDialog();
        return;
      }
      _startQuestion();
    } else {
      _errors += 1;
      _correctStreak = 0;
      _shakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _lockInput = false;
      setState(() {});
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
    _resetGame();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 900;
    final cardWidth =
        (isTablet ? size.width * 0.4 : size.width * 0.85).clamp(220.0, 460.0);
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
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxImage = min(
                            constraints.maxWidth * (isTablet ? 0.75 : 0.7),
                            constraints.maxHeight - (isTablet ? 40.0 : 32.0),
                          ).clamp(80.0, isTablet ? 200.0 : 150.0);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_current != null)
                                SizedBox(
                                  width: maxImage,
                                  height: maxImage,
                                  child: Image.asset(
                                    _current!.imagePath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              SizedBox(height: isTablet ? 6 : 4),
                              IconButton(
                                onPressed: _speakCurrentEmotion,
                                icon: const Icon(Icons.volume_up_rounded),
                                iconSize: isTablet ? 28 : 22,
                                color: const Color(0xFF1E212D),
                                splashRadius: isTablet ? 24 : 20,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    );
                  },
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: _options.map((item) {
                      return GestureDetector(
                        onTap: () => _onAnswer(item),
                        child: Container(
                          width: isTablet ? 160 : 130,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E212D),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
}

class _EmotionItem {
  final String label;
  final String imagePath;

  const _EmotionItem({
    required this.label,
    required this.imagePath,
  });
}

const _emotions = [
  _EmotionItem(label: 'فرح', imagePath: 'assets/emotions/happy.png'),
  _EmotionItem(label: 'حزن', imagePath: 'assets/emotions/sad.png'),
  _EmotionItem(label: 'غضب', imagePath: 'assets/emotions/angry.png'),
  _EmotionItem(label: 'خوف', imagePath: 'assets/emotions/scared.png'),
];
