import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/services/stats_store.dart';

class PuzzlesGame extends StatefulWidget {
  const PuzzlesGame({super.key});

  @override
  State<PuzzlesGame> createState() => _PuzzlesGameState();
}

class _PuzzlesGameState extends State<PuzzlesGame> {
  final Random _random = Random();
  final AudioPlayer _player = AudioPlayer();

  final List<int> _puzzleIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  int _level = 1; // 1=2x2, 2=3x3, 3=4x4
  int _levelStars = 0;
  int _levelRoundIndex = 0; // progress within level (all images)
  int _errors = 0;
  int _correct = 0;
  DateTime _startedAt = DateTime.now();
  bool _saved = false;
  bool _hasPlayed = false;

  int _currentId = 1;
  late int _size; // grid size
  late List<int?> _board; // index or null for empty
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
    _player.dispose();
    super.dispose();
  }

  void _startLevel() {
    _size = _level == 1 ? 2 : (_level == 2 ? 3 : 4);
    _levelRoundIndex = 0;
    _currentId = _puzzleIds[_levelRoundIndex];
    _statusText = '';
    _hasPlayed = false;
    _saved = false;
    _startedAt = DateTime.now();

    // solved state
    _board = List<int?>.generate(
      _size * _size,
      (i) => i == _size * _size - 1 ? null : i,
    );

    final moves = _level == 1 ? 20 : (_level == 2 ? 35 : 50);
    _shuffleBoardWithCheck(moves);
    setState(() {});
  }

  void _nextPuzzleInLevel() {
    _levelRoundIndex += 1;
    if (_levelRoundIndex >= _puzzleIds.length) {
      _showLevelDialog();
      return;
    }
    _currentId = _puzzleIds[_levelRoundIndex];
    _statusText = '';
    _hasPlayed = false;
    _saved = false;
    _startedAt = DateTime.now();
    _board = List<int?>.generate(
      _size * _size,
      (i) => i == _size * _size - 1 ? null : i,
    );
    final moves = _level == 1 ? 20 : (_level == 2 ? 35 : 50);
    _shuffleBoardWithCheck(moves);
    setState(() {});
  }

  void _shuffleBoard(int moves) {
    for (var i = 0; i < moves; i++) {
      final emptyIndex = _board.indexOf(null);
      final neighbors = _neighbors(emptyIndex);
      final pick = neighbors[_random.nextInt(neighbors.length)];
      _swap(emptyIndex, pick);
    }
  }

  void _shuffleBoardWithCheck(int moves) {
    _shuffleBoard(moves);
    var guard = 0;
    while (_isSolved() && guard < 5) {
      _shuffleBoard(moves);
      guard += 1;
    }
  }

  List<int> _neighbors(int index) {
    final row = index ~/ _size;
    final col = index % _size;
    final list = <int>[];
    if (row > 0) list.add(index - _size);
    if (row < _size - 1) list.add(index + _size);
    if (col > 0) list.add(index - 1);
    if (col < _size - 1) list.add(index + 1);
    return list;
  }

  void _swap(int a, int b) {
    final tmp = _board[a];
    _board[a] = _board[b];
    _board[b] = tmp;
  }

  String _tilePath(int index) {
    final row = index ~/ _size;
    final col = index % _size;
    final levelTag = _level == 1 ? 'l1' : (_level == 2 ? 'l2' : 'l3');
    final folder = _level == 1
        ? 'level_1_2x2'
        : (_level == 2 ? 'level_2_3x3' : 'level_3_4x4');
    return 'assets/games/puzzles/$_currentId/$folder/${_currentId}_${levelTag}_${row}_${col}.png';
  }

  String _fullImagePath() {
    final levelTag = _level == 1 ? 'l1' : (_level == 2 ? 'l2' : 'l3');
    final folder = _level == 1
        ? 'level_1_2x2'
        : (_level == 2 ? 'level_2_3x3' : 'level_3_4x4');
    return 'assets/games/puzzles/$_currentId/$folder/${_currentId}_${levelTag}_full.png';
  }

  void _onTileTap(int index) {
    final emptyIndex = _board.indexOf(null);
    if (_neighbors(emptyIndex).contains(index)) {
      setState(() => _swap(index, emptyIndex));
      _hasPlayed = true;
      if (_isSolved()) {
        _statusText = 'برافو!';
        _correct += 1;
        _player.play(AssetSource('voices/winner.mp3'));
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          _nextPuzzleInLevel();
        });
      } else {
        _statusText = '';
      }
    }
  }

  bool _isSolved() {
    for (var i = 0; i < _board.length - 1; i++) {
      if (_board[i] != i) return false;
    }
    return _board.last == null;
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
        gameKey: 'puzzle',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  Future<void> _showLevelDialog() async {
    final isLast = _level >= 3;
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
                  width: 140,
                  height: 140,
                  repeat: false,
                ),
                const SizedBox(height: 8),
                Text(
                  isLast ? 'أحسنت!' : 'برافو!',
                  style: GoogleFonts.almarai(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E212D),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isLast ? 'إعادة اللعب' : 'المستوى التالي'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (isLast) {
      _level = 1;
      _levelStars = 0;
      _errors = 0;
      _correct = 0;
      _saved = false;
      _hasPlayed = false;
      _startedAt = DateTime.now();
    } else {
      _level += 1;
      _levelStars = _level - 1;
    }
    _startLevel();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 900;
    final isLandscape = size.width > size.height;
    final boardSize = (min(size.width, size.height) * (isTablet ? 0.5 : 0.46))
        .clamp(isTablet ? 240.0 : 180.0, isTablet ? 420.0 : 280.0);
    final fullSize = boardSize;
    const backgroundPath = 'assets/gamenumbers/bg.png';

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
                SizedBox(height: isTablet ? 8 : 4),
                Text(
                  'ركّب الصورة',
                  style: GoogleFonts.almarai(
                    fontSize: isTablet ? 24 : 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E212D),
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 4),
                Padding(
                  padding: EdgeInsets.only(top: isTablet ? 14 : 8),
                  child: isLandscape
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: fullSize,
                              height: fullSize,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Image.asset(
                                _fullImagePath(),
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: isTablet ? 30 : 16),
                            Container(
                              width: boardSize,
                              height: boardSize,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _size,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: _board.length,
                                itemBuilder: (context, index) {
                                  final value = _board[index];
                                  if (value == null) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.35),
                                          width: 1,
                                        ),
                                      ),
                                    );
                                  }
                                  return GestureDetector(
                                    onTap: () => _onTileTap(index),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        _tilePath(value),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Container(
                              width: fullSize,
                              height: fullSize,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Image.asset(
                                _fullImagePath(),
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: isTablet ? 16 : 10),
                            Container(
                              width: boardSize,
                              height: boardSize,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _size,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: _board.length,
                                itemBuilder: (context, index) {
                                  final value = _board[index];
                                  if (value == null) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.35),
                                          width: 1,
                                        ),
                                      ),
                                    );
                                  }
                                  return GestureDetector(
                                    onTap: () => _onTileTap(index),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        _tilePath(value),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  _statusText,
                  style: GoogleFonts.almarai(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E212D),
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
