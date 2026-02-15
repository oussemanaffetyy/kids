import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/constants.dart';
import 'package:project_v1/services/stats_store.dart';
import 'package:project_v1/services/tts_helper.dart';

class FamilyGame extends StatelessWidget {
  const FamilyGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FamilyGameBody();
  }
}

class _FamilyGameBody extends StatefulWidget {
  const _FamilyGameBody();

  @override
  State<_FamilyGameBody> createState() => _FamilyGameBodyState();
}

class _FamilyGameBodyState extends State<_FamilyGameBody>
    with TickerProviderStateMixin {
  final AudioPlayer _tapPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final Random _random = Random();

  int _level = 1;
  int _correctStreak = 0;
  int _levelStars = 0;
  int _totalCorrect = 0;
  int _errors = 0;
  int _correct = 0;
  DateTime _startedAt = DateTime.now();
  bool _saved = false;
  bool _hasPlayed = false;
  int _targetIndex = 0;
  int _lastTargetIndex = -1;
  List<int> _options = [];
  bool _showStars = false;
  bool _lockInput = false;
  int? _wrongIndex;
  String _praiseText = '';

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));
    Future<void>(() async {
      await TtsHelper.configureArabic(
        _tts,
        pitch: 1.0,
        volume: 0.8,
        speechRate: 0.45,
      );
    });
    _startRound();
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
    _tts.stop();
    _tapPlayer.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startRound() {
    _showStars = false;
    _lockInput = false;
    _wrongIndex = null;
    _praiseText = '';

    if (familyList.isEmpty) return;
    var next = _random.nextInt(familyList.length);
    if (familyList.length > 1) {
      while (next == _lastTargetIndex) {
        next = _random.nextInt(familyList.length);
      }
    }
    _targetIndex = next;
    _lastTargetIndex = next;

    final optionCount = _level == 1 ? 2 : (_level == 2 ? 3 : 4);
    final set = <int>{_targetIndex};
    while (set.length < optionCount) {
      set.add(_random.nextInt(familyList.length));
    }
    _options = set.toList()..shuffle(_random);

    setState(() {});
    _speakCurrentName();
  }

  Future<void> _speakCurrentName() async {
    if (!mounted || familyList.isEmpty) return;
    final name = familyList[_targetIndex]['name'] as String?;
    if (name == null || name.isEmpty) return;
    await TtsHelper.speak(_tts, name);
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
        gameKey: 'family',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  Future<void> _onPick(int index) async {
    if (_lockInput) return;
    _lockInput = true;
    _hasPlayed = true;
    await _tapPlayer.play(AssetSource('voices/tap_click.mp3'));

    if (index == _targetIndex) {
      setState(() {
        _showStars = true;
        _praiseText = 'ممتاز! هذا هو ${familyList[_targetIndex]['name']}';
      });

      _correctStreak += 1;
      _totalCorrect += 1;
      _correct += 1;
      if (_correctStreak >= 5 && _level < 3) {
        _level += 1;
        _correctStreak = 0;
        _levelStars = (_level - 1).clamp(0, 3);
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (_level >= 3 && _correctStreak >= 5) {
        setState(() => _levelStars = 3);
        await _saveStatsIfNeeded();
        await _showWinDialog();
        return;
      }
      _startRound();
    } else {
      _errors += 1;
      setState(() => _wrongIndex = index);
      _shakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() => _wrongIndex = null);
      _lockInput = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    const backgroundPath = 'assets/gamenumbers/bg.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final maxH = constraints.maxHeight;
                final cardSize = isTablet
                    ? (maxH * 0.43).clamp(180.0, 270.0)
                    : (maxH * 0.48).clamp(150.0, 230.0);
                final chipFont = isTablet ? 16.0 : 13.0;
                final chipHorizontal = isTablet ? 14.0 : 10.0;
                final chipVertical = isTablet ? 7.0 : 5.0;

                return Column(
                  children: [
                    SizedBox(height: isTablet ? 60 : 50),
                    Text(
                      'من هذا؟',
                      style: GoogleFonts.almarai(
                        fontSize: isTablet ? 24 : 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E212D),
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    AnimatedOpacity(
                      opacity: _praiseText.isEmpty ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _praiseText,
                        style: GoogleFonts.almarai(
                          fontSize: isTablet ? 18 : 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E212D),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 10 : 6),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: isTablet ? 16 : 10),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: maxH * (isTablet ? 0.68 : 0.66),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: cardSize,
                                    height: cardSize,
                                    padding: EdgeInsets.all(isTablet ? 12 : 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Image.asset(
                                      familyList[_targetIndex]['imagePath']
                                          as String,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: isTablet ? 8 : 6,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Center(
                                        child: InkWell(
                                          onTap: _speakCurrentName,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          child: Container(
                                            width: isTablet ? 44 : 38,
                                            height: isTablet ? 44 : 38,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFDCE7F8),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.volume_up_rounded,
                                              size: isTablet ? 23 : 20,
                                              color: const Color(0xFF1E212D),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_showStars)
                                    Lottie.asset(
                                      'assets/json/stars.json',
                                      width: cardSize * 0.8,
                                      height: cardSize * 0.8,
                                      repeat: false,
                                    ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 16 : 10),
                              AnimatedBuilder(
                                animation: _shakeAnim,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(_shakeAnim.value, 0),
                                    child: child,
                                  );
                                },
                                child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(maxWidth: maxW * 0.94),
                                  child: Wrap(
                                    spacing: isTablet ? 12 : 8,
                                    runSpacing: isTablet ? 12 : 8,
                                    alignment: WrapAlignment.center,
                                    children: _options.map((index) {
                                      final isWrong = _wrongIndex == index;
                                      final name =
                                          familyList[index]['name'] as String;
                                      return GestureDetector(
                                        onTap: () => _onPick(index),
                                        child: Container(
                                          constraints: BoxConstraints(
                                            minWidth: isTablet ? 110 : 82,
                                            maxWidth: isTablet ? 190 : 140,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: chipHorizontal,
                                            vertical: chipVertical,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.78),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: isWrong
                                                  ? const Color(0xFFE57373)
                                                  : Colors.white
                                                      .withOpacity(0.9),
                                              width: isWrong ? 1.4 : 1,
                                            ),
                                          ),
                                          child: Text(
                                            name,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.almarai(
                                              fontSize: chipFont,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF1E212D),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

    _level = 1;
    _correctStreak = 0;
    _levelStars = 0;
    _totalCorrect = 0;
    _errors = 0;
    _correct = 0;
    _saved = false;
    _hasPlayed = false;
    _startedAt = DateTime.now();
    _startRound();
  }
}
