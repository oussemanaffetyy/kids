import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/services/stats_store.dart';
import 'package:project_v1/services/tts_helper.dart';

class LettersQuizGame extends StatefulWidget {
  const LettersQuizGame({super.key});

  @override
  State<LettersQuizGame> createState() => _LettersQuizGameState();
}

class _LettersQuizGameState extends State<LettersQuizGame>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _tapPlayer = AudioPlayer();
  final Random _random = Random();

  int _questionIndex = 0;
  List<int> _questionOrder = [];
  _LetterItem? _current;
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
    _tapPlayer.dispose();
    super.dispose();
  }

  void _resetQuiz() {
    _questionOrder = List.generate(_letterItems.length, (i) => i)
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
    _current = _letterItems[idx];
    final wrongCount = _level == 1 ? 1 : (_level == 2 ? 2 : 3);
    _options = _buildOptions(_current!.letter, wrongCount);
    setState(() {});
    _speakPrompt();
  }

  List<String> _buildOptions(String correct, int wrongCount) {
    final set = <String>{correct};
    while (set.length < (wrongCount + 1)) {
      final letter = _letters[_random.nextInt(_letters.length)];
      if (letter != correct) set.add(letter);
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
        gameKey: 'letters',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  Future<void> _speakPrompt() async {
    if (_current == null) return;
    await TtsHelper.speak(_tts, _current!.word);
    await Future.delayed(const Duration(milliseconds: 300));
    await TtsHelper.speak(_tts, _current!.letter);
  }

  Future<void> _onOptionTap(String letter) async {
    if (_lockInput) return;
    _lockInput = true;
    _hasPlayed = true;
    await _tapPlayer.play(AssetSource('voices/tap_click.mp3'));

    if (_current == null) return;
    if (letter == _current!.letter) {
      setState(() {
        _selected = letter;
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
      if (_questionIndex >= _letterItems.length) {
        await _saveStatsIfNeeded();
        await _showWinDialog();
        return;
      }
      _startQuestion();
    } else {
      _selected = letter;
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
    final cardWidth =
        (isTablet ? size.width * 0.36 : size.width * 0.78).clamp(200.0, 420.0);
    final backgroundPath = 'assets/gamenumbers/bg.png';
    final cardPadding = isTablet ? 16.0 : 10.0;

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
                const SizedBox(height: 46),
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
                                  (isTablet ? 0.78 : 0.68))
                              .clamp(isTablet ? 140.0 : 110.0,
                                  isTablet ? 220.0 : 180.0);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_current != null)
                                Image.asset(
                                  _current!.avatarPath,
                                  width: maxAvatar,
                                  height: maxAvatar,
                                  fit: BoxFit.contain,
                                ),
                              SizedBox(height: isTablet ? 12 : 6),
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
                SizedBox(height: isTablet ? 12 : 8),
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    );
                  },
                  child: Wrap(
                    spacing: isTablet ? 16 : 10,
                    runSpacing: isTablet ? 12 : 8,
                    alignment: WrapAlignment.center,
                    children: _options.map((letter) {
                      final isSelected = _selected == letter;
                      return GestureDetector(
                        onTap: () => _onOptionTap(letter),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: isTablet ? 120 : 96,
                              height: isTablet ? 120 : 96,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(
                                _letterImage(letter),
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (isSelected && _showStars)
                              Lottie.asset(
                                'assets/json/stars.json',
                                width: isTablet ? 140 : 110,
                                height: isTablet ? 140 : 110,
                                repeat: false,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterItem {
  final String word;
  final String letter;
  final String avatarPath;
  final String letterImagePath;

  const _LetterItem({
    required this.word,
    required this.letter,
    required this.avatarPath,
    required this.letterImagePath,
  });
}

const _letters = [
  'أ',
  'ب',
  'ت',
  'ث',
  'ج',
  'ح',
  'خ',
  'د',
  'ذ',
  'ر',
  'ز',
  'س',
  'ش',
  'ص',
  'ض',
  'ط',
  'ظ',
  'ع',
  'غ',
  'ف',
  'ق',
  'ك',
  'ل',
  'م',
  'ن',
  'ه',
  'و',
  'ي',
];

String _letterImage(String letter) {
  return 'assets/letters/samples/$letter.png';
}

const _letterItems = [
  _LetterItem(
    word: 'أرنب',
    letter: 'أ',
    avatarPath: 'assets/letters/avatars/أرنب.png',
    letterImagePath: 'assets/letters/samples/أ.png',
  ),
  _LetterItem(
    word: 'بطة',
    letter: 'ب',
    avatarPath: 'assets/letters/avatars/بطة.png',
    letterImagePath: 'assets/letters/samples/ب.png',
  ),
  _LetterItem(
    word: 'تفاح',
    letter: 'ت',
    avatarPath: 'assets/letters/avatars/تفاح.png',
    letterImagePath: 'assets/letters/samples/ت.png',
  ),
  _LetterItem(
    word: 'ثلج',
    letter: 'ث',
    avatarPath: 'assets/letters/avatars/ثلج.png',
    letterImagePath: 'assets/letters/samples/ث.png',
  ),
  _LetterItem(
    word: 'جزر',
    letter: 'ج',
    avatarPath: 'assets/letters/avatars/جَزَر.png',
    letterImagePath: 'assets/letters/samples/ج.png',
  ),
  _LetterItem(
    word: 'حصان',
    letter: 'ح',
    avatarPath: 'assets/letters/avatars/حصان.png',
    letterImagePath: 'assets/letters/samples/ح.png',
  ),
  _LetterItem(
    word: 'خيمة',
    letter: 'خ',
    avatarPath: 'assets/letters/avatars/خيمة.png',
    letterImagePath: 'assets/letters/samples/خ.png',
  ),
  _LetterItem(
    word: 'دولفين',
    letter: 'د',
    avatarPath: 'assets/letters/avatars/دولفين.png',
    letterImagePath: 'assets/letters/samples/د.png',
  ),
  _LetterItem(
    word: 'ذرة',
    letter: 'ذ',
    avatarPath: 'assets/letters/avatars/ذُره.png',
    letterImagePath: 'assets/letters/samples/ذ.png',
  ),
  _LetterItem(
    word: 'ريشة',
    letter: 'ر',
    avatarPath: 'assets/letters/avatars/ريشة.png',
    letterImagePath: 'assets/letters/samples/ر.png',
  ),
  _LetterItem(
    word: 'زرافة',
    letter: 'ز',
    avatarPath: 'assets/letters/avatars/زرافة.png',
    letterImagePath: 'assets/letters/samples/ز.png',
  ),
  _LetterItem(
    word: 'سلحفاة',
    letter: 'س',
    avatarPath: 'assets/letters/avatars/سلحفاة.png',
    letterImagePath: 'assets/letters/samples/س.png',
  ),
  _LetterItem(
    word: 'شمعة',
    letter: 'ش',
    avatarPath: 'assets/letters/avatars/شمعة.png',
    letterImagePath: 'assets/letters/samples/ش.png',
  ),
  _LetterItem(
    word: 'صقر',
    letter: 'ص',
    avatarPath: 'assets/letters/avatars/صقر.png',
    letterImagePath: 'assets/letters/samples/ص.png',
  ),
  _LetterItem(
    word: 'ضفدع',
    letter: 'ض',
    avatarPath: 'assets/letters/avatars/ضفدع.png',
    letterImagePath: 'assets/letters/samples/ض.png',
  ),
  _LetterItem(
    word: 'طائرة',
    letter: 'ط',
    avatarPath: 'assets/letters/avatars/طائرة.png',
    letterImagePath: 'assets/letters/samples/ط.png',
  ),
  _LetterItem(
    word: 'ظرف',
    letter: 'ظ',
    avatarPath: 'assets/letters/avatars/ظرف.png',
    letterImagePath: 'assets/letters/samples/ظ.png',
  ),
  _LetterItem(
    word: 'عصفور',
    letter: 'ع',
    avatarPath: 'assets/letters/avatars/عصفور.png',
    letterImagePath: 'assets/letters/samples/ع.png',
  ),
  _LetterItem(
    word: 'غزالة',
    letter: 'غ',
    avatarPath: 'assets/letters/avatars/غزالة.png',
    letterImagePath: 'assets/letters/samples/غ.png',
  ),
  _LetterItem(
    word: 'فراولة',
    letter: 'ف',
    avatarPath: 'assets/letters/avatars/فراولة.png',
    letterImagePath: 'assets/letters/samples/ف.png',
  ),
  _LetterItem(
    word: 'قلم',
    letter: 'ق',
    avatarPath: 'assets/letters/avatars/قلم.png',
    letterImagePath: 'assets/letters/samples/ق.png',
  ),
  _LetterItem(
    word: 'كرة',
    letter: 'ك',
    avatarPath: 'assets/letters/avatars/كرة.png',
    letterImagePath: 'assets/letters/samples/ك.png',
  ),
  _LetterItem(
    word: 'لمبة',
    letter: 'ل',
    avatarPath: 'assets/letters/avatars/لمبة.png',
    letterImagePath: 'assets/letters/samples/ل.png',
  ),
  _LetterItem(
    word: 'موز',
    letter: 'م',
    avatarPath: 'assets/letters/avatars/موز.png',
    letterImagePath: 'assets/letters/samples/م.png',
  ),
  _LetterItem(
    word: 'نجمة',
    letter: 'ن',
    avatarPath: 'assets/letters/avatars/نجمة.png',
    letterImagePath: 'assets/letters/samples/ن.png',
  ),
  _LetterItem(
    word: 'هرم',
    letter: 'ه',
    avatarPath: 'assets/letters/avatars/هرم.png',
    letterImagePath: 'assets/letters/samples/ه.png',
  ),
  _LetterItem(
    word: 'وردة',
    letter: 'و',
    avatarPath: 'assets/letters/avatars/وردة.png',
    letterImagePath: 'assets/letters/samples/و.png',
  ),
  _LetterItem(
    word: 'يد',
    letter: 'ي',
    avatarPath: 'assets/letters/avatars/يد.png',
    letterImagePath: 'assets/letters/samples/ي.png',
  ),
];
