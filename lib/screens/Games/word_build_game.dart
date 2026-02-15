import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/services/stats_store.dart';
import 'package:project_v1/services/tts_helper.dart';

class WordBuildGame extends StatelessWidget {
  const WordBuildGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WordBuildGameBody();
  }
}

class _WordBuildGameBody extends StatefulWidget {
  const _WordBuildGameBody();

  @override
  State<_WordBuildGameBody> createState() => _WordBuildGameBodyState();
}

class _WordBuildGameBodyState extends State<_WordBuildGameBody>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final Random _random = Random();

  int _level = 1;
  int _levelStars = 0;
  int _index = 0;
  List<int> _order = [];
  _WordItem? _current;
  List<_OptionItem> _options = [];
  List<String> _slots = [];
  List<int?> _slotOptionIds = [];
  Set<int> _usedOptions = {};
  int? _selectedSlot;
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
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _sfxPlayer.setVolume(1.0);
    });

    _startLevel(1);
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
    _shakeCtrl.dispose();
    _tts.stop();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _startLevel(int level) {
    _level = level;
    _index = 0;
    _order = List.generate(_levelItems[level]!.length, (i) => i)
      ..shuffle(_random);
    _loadWord();
    if (_level < 3) {
      _speakWord();
    }
  }

  void _loadWord() {
    _lockInput = false;
    _showStars = false;
    _selectedReset();
    final list = _levelItems[_level]!;
    final idx = _order[_index];
    _current = list[idx];

    final letters = _current!.word.split('');
    _slots = List.filled(letters.length, '');
    _slotOptionIds = List<int?>.filled(letters.length, null);
    final wrongCount = _level == 1 ? 0 : (_level == 2 ? 1 : 2);
    _options = _buildOptions(letters, wrongCount);
    _usedOptions.clear();
    setState(() {});
  }

  void _selectedReset() {
    _selectedSlot = null;
  }

  List<_OptionItem> _buildOptions(List<String> letters, int wrongCount) {
    final options = <String>[...letters];
    while (wrongCount > 0) {
      final ch = _letterPool[_random.nextInt(_letterPool.length)];
      if (!letters.contains(ch)) {
        options.add(ch);
        wrongCount--;
      }
    }
    options.shuffle(_random);
    return List.generate(
      options.length,
      (i) => _OptionItem(id: i, letter: options[i]),
    );
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
        gameKey: 'word_build',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  Future<void> _speakWord() async {
    if (_current == null) return;
    await TtsHelper.speak(_tts, _current!.word);
  }

  Future<void> _playSfx(String assetPath) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(
        AssetSource(assetPath),
        mode: PlayerMode.lowLatency,
        volume: 1.0,
      );
    } catch (_) {}
  }

  Future<void> _onDropLetter(_DragLetter drag, int slotIndex) async {
    if (_lockInput) return;
    _hasPlayed = true;
    if (_current == null) return;

    final targetLetters = _current!.word.split('');
    if (slotIndex >= targetLetters.length) return;

    if (drag.fromSlot != null) {
      // swap between slots
      final from = drag.fromSlot!;
      if (from == slotIndex) return;
      _selectedSlot = null;
      setState(() {
        final tmp = _slots[slotIndex];
        _slots[slotIndex] = _slots[from];
        _slots[from] = tmp;

        final tmpId = _slotOptionIds[slotIndex];
        _slotOptionIds[slotIndex] = _slotOptionIds[from];
        _slotOptionIds[from] = tmpId;
      });
    } else if (drag.fromOption != null) {
      // place or replace from options.
      if (_usedOptions.contains(drag.fromOption)) return;
      _selectedSlot = null;
      setState(() {
        final replacedId = _slotOptionIds[slotIndex];
        if (replacedId != null) {
          _usedOptions.remove(replacedId);
        }
        _slots[slotIndex] = drag.letter;
        _slotOptionIds[slotIndex] = drag.fromOption!;
        _usedOptions.add(drag.fromOption!);
      });
    }

    await _checkAfterChange(slotIndex);
  }

  void _returnLetterToOptions(_DragLetter drag, _OptionItem opt) {
    if (_lockInput) return;
    if (drag.fromSlot == null) return;
    if (drag.optionId != opt.id) return;

    final fromSlot = drag.fromSlot!;
    if (fromSlot < 0 || fromSlot >= _slots.length) return;
    if (_slotOptionIds[fromSlot] != opt.id) return;

    setState(() {
      _slots[fromSlot] = '';
      _slotOptionIds[fromSlot] = null;
      _usedOptions.remove(opt.id);
      if (_selectedSlot == fromSlot) {
        _selectedSlot = null;
      }
    });
  }

  void _onSlotTap(int index) {
    if (_lockInput) return;
    if (_slots[index].isEmpty) {
      if (_selectedSlot != null) {
        setState(() {
          _slots[index] = _slots[_selectedSlot!];
          _slots[_selectedSlot!] = '';

          _slotOptionIds[index] = _slotOptionIds[_selectedSlot!];
          _slotOptionIds[_selectedSlot!] = null;
          _selectedSlot = null;
        });
      }
      return;
    }

    if (_selectedSlot == null) {
      setState(() => _selectedSlot = index);
      return;
    }
    if (_selectedSlot == index) {
      // Tap same selected slot again: clear it and return letter to options.
      setState(() {
        final optionId = _slotOptionIds[index];
        if (optionId != null) {
          _usedOptions.remove(optionId);
        }
        _slots[index] = '';
        _slotOptionIds[index] = null;
        _selectedSlot = null;
      });
      return;
    }
    setState(() {
      final tmp = _slots[index];
      _slots[index] = _slots[_selectedSlot!];
      _slots[_selectedSlot!] = tmp;

      final tmpId = _slotOptionIds[index];
      _slotOptionIds[index] = _slotOptionIds[_selectedSlot!];
      _slotOptionIds[_selectedSlot!] = tmpId;
      _selectedSlot = null;
    });
  }

  Future<void> _onOptionTap(_OptionItem opt) async {
    if (_lockInput) return;
    if (_usedOptions.contains(opt.id)) return;
    final emptyIndex = _slots.indexOf('');
    int targetIndex = emptyIndex;
    if (targetIndex == -1) {
      if (_selectedSlot == null) return;
      targetIndex = _selectedSlot!;
    }
    _hasPlayed = true;
    setState(() {
      final replacedId = _slotOptionIds[targetIndex];
      if (replacedId != null) {
        _usedOptions.remove(replacedId);
      }
      _slots[targetIndex] = opt.letter;
      _slotOptionIds[targetIndex] = opt.id;
      _usedOptions.add(opt.id);
      _selectedSlot = null;
    });
    await _checkAfterChange(targetIndex);
  }

  Future<void> _checkAfterChange(int slotIndex) async {
    if (_current == null) return;
    final targetLetters = _current!.word.split('');
    if (_slots.every((s) => s.isNotEmpty)) {
      if (_slots.join() != targetLetters.join()) {
        _errors += 1;
        await _playSfx('voices/wrong.mp3');
        _shakeCtrl.forward(from: 0);
        return;
      }
      await _playSfx('voices/correct.mp3');
      _lockInput = true;
      _correct += 1;
      setState(() => _showStars = true);
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _showStars = false);

      _index += 1;
      final list = _levelItems[_level]!;
      if (_index >= list.length) {
        if (_level < 3) {
          _levelStars = _level;
          _startLevel(_level + 1);
          return;
        }
        await _saveStatsIfNeeded();
        await _showWinDialog();
        return;
      }
      _loadWord();
      if (_level < 3) {
        _speakWord();
      }
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
    _levelStars = 0;
    _startLevel(1);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final cardWidth =
        (isTablet ? size.width * 0.38 : size.width * 0.78).clamp(200.0, 440.0);
    const backgroundPath = 'assets/gamenumbers/bg.png';
    final cardPadding = isTablet ? 16.0 : 10.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(backgroundPath, fit: BoxFit.cover),
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
                        color: Colors.white.withOpacity(0.85),
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
                                GestureDetector(
                                  onTap: _speakWord,
                                  child: Image.asset(
                                    _current!.imagePath,
                                    width: maxAvatar,
                                    height: maxAvatar,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              SizedBox(height: isTablet ? 12 : 6),
                              IconButton(
                                onPressed: _speakWord,
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
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    );
                  },
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Wrap(
                      spacing: isTablet ? 10 : 8,
                      runSpacing: isTablet ? 10 : 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(_slots.length, (i) {
                        final slot = _slots[i];
                        return DragTarget<_DragLetter>(
                          onAccept: (data) => _onDropLetter(data, i),
                          builder: (context, candidateData, rejectedData) {
                            final isSelected = _selectedSlot == i;
                            final box = Container(
                              width: isTablet ? 60 : 52,
                              height: isTablet ? 60 : 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4DA3FF)
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  slot,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E212D),
                                  ),
                                ),
                              ),
                            );
                            if (slot.isEmpty) {
                              return GestureDetector(
                                onTap: () => _onSlotTap(i),
                                child: box,
                              );
                            }
                            return Draggable<_DragLetter>(
                              data: _DragLetter(
                                letter: slot,
                                fromSlot: i,
                                optionId: _slotOptionIds[i],
                              ),
                              feedback: Material(
                                color: Colors.transparent,
                                child: box,
                              ),
                              childWhenDragging: Container(
                                width: isTablet ? 60 : 52,
                                height: isTablet ? 60 : 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () => _onSlotTap(i),
                                child: box,
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    );
                  },
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _options.map((opt) {
                        final disabled = _usedOptions.contains(opt.id);
                        final tile = Container(
                          width: isTablet ? 64 : 56,
                          height: isTablet ? 64 : 56,
                          decoration: BoxDecoration(
                            color: disabled
                                ? const Color(0xFFE8E8E8)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: disabled
                                  ? Colors.white
                                  : const Color(0xFFB6D4FF),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              opt.letter,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: disabled
                                    ? const Color(0xFF1E212D).withOpacity(0.35)
                                    : const Color(0xFF1E212D),
                              ),
                            ),
                          ),
                        );
                        final optionBody = disabled
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  tile,
                                  if (_showStars)
                                    Lottie.asset(
                                      'assets/json/stars.json',
                                      width: isTablet ? 90 : 70,
                                      height: isTablet ? 90 : 70,
                                      repeat: false,
                                    ),
                                ],
                              )
                            : GestureDetector(
                                onTap: () => _onOptionTap(opt),
                                child: Draggable<_DragLetter>(
                                  data: _DragLetter(
                                    letter: opt.letter,
                                    fromOption: opt.id,
                                  ),
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: tile,
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.4,
                                    child: tile,
                                  ),
                                  child: tile,
                                ),
                              );

                        return DragTarget<_DragLetter>(
                          onWillAccept: (drag) =>
                              drag != null &&
                              drag.fromSlot != null &&
                              drag.optionId == opt.id,
                          onAccept: (drag) => _returnLetterToOptions(drag, opt),
                          builder: (context, candidateData, rejectedData) {
                            return AnimatedScale(
                              duration: const Duration(milliseconds: 120),
                              scale: candidateData.isNotEmpty ? 1.08 : 1.0,
                              child: optionBody,
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WordItem {
  final String word;
  final String imagePath;

  const _WordItem({
    required this.word,
    required this.imagePath,
  });
}

class _OptionItem {
  final int id;
  final String letter;

  const _OptionItem({
    required this.id,
    required this.letter,
  });
}

class _DragLetter {
  final String letter;
  final int? fromSlot;
  final int? fromOption;
  final int? optionId;

  const _DragLetter({
    required this.letter,
    this.fromSlot,
    this.fromOption,
    this.optionId,
  });
}

const _letterPool = [
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

const _levelItems = {
  1: [
    _WordItem(word: 'يد', imagePath: 'assets/letters/avatars/يد.png'),
    _WordItem(word: 'قط', imagePath: 'assets/animals/cat.png'),
    _WordItem(word: 'موز', imagePath: 'assets/letters/avatars/موز.png'),
    _WordItem(word: 'قلم', imagePath: 'assets/letters/avatars/قلم.png'),
  ],
  2: [
    _WordItem(word: 'كرة', imagePath: 'assets/letters/avatars/كرة.png'),
    _WordItem(word: 'أسد', imagePath: 'assets/animals/leo.png'),
    _WordItem(word: 'حصان', imagePath: 'assets/letters/avatars/حصان.png'),
    _WordItem(word: 'تفاح', imagePath: 'assets/letters/avatars/تفاح.png'),
  ],
  3: [
    _WordItem(word: 'فراولة', imagePath: 'assets/letters/avatars/فراولة.png'),
    _WordItem(word: 'عصفور', imagePath: 'assets/letters/avatars/عصفور.png'),
    _WordItem(word: 'بطاطس', imagePath: 'assets/vegetables/بطاطس.png'),
    _WordItem(word: 'دولفين', imagePath: 'assets/letters/avatars/دولفين.png'),
  ],
};
