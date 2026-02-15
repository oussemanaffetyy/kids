import 'dart:math';
import 'package:flutter/material.dart';
import 'package:project_v1/constants.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:project_v1/services/stats_store.dart';

class Memory extends StatefulWidget {
  const Memory({super.key});

  @override
  State<Memory> createState() => _MemoryState();
}

class _MemoryState extends State<Memory> with TickerProviderStateMixin {
  final player = AudioPlayer();
  final GameLogic _gameLogic = GameLogic();

  int tries = 0;
  int score = 0;
  int _errors = 0;
  int _correct = 0;
  DateTime _startedAt = DateTime.now();
  bool _saved = false;
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _gameLogic.initGame();
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
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
        gameKey: 'memory',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  Future<void> _onCardTap(int index) async {
    if (_gameLogic.matchCheck.length == 2) return;

    if (_gameLogic.gameImg[index] != _gameLogic.hiddenCardPath) return;

    setState(() {
      _hasPlayed = true;
      tries++;
      _gameLogic.gameImg[index] = _gameLogic.cardsList[index];
      _gameLogic.matchCheck.add({index: _gameLogic.cardsList[index]});
    });

    if (_gameLogic.matchCheck.length == 2) {
      final aKey = _gameLogic.matchCheck[0].keys.first;
      final bKey = _gameLogic.matchCheck[1].keys.first;
      final aVal = _gameLogic.matchCheck[0].values.first;
      final bVal = _gameLogic.matchCheck[1].values.first;

      if (aVal == bVal && aKey != bKey) {
        setState(() {
          score += 100;
          _correct += 1;
        });
        await player.play(AssetSource("voices/correct.mp3"));
        _gameLogic.matchCheck.clear();
      } else {
        await player.play(AssetSource("voices/wrong.mp3"));
        Vibration.vibrate(duration: 200);
        setState(() => _errors += 1);

        await Future.delayed(const Duration(milliseconds: 450));
        setState(() {
          _gameLogic.gameImg[aKey] = _gameLogic.hiddenCardPath;
          _gameLogic.gameImg[bKey] = _gameLogic.hiddenCardPath;
          _gameLogic.matchCheck.clear();
        });
      }

      // ✅ winner
      if (!_gameLogic.gameImg.contains(_gameLogic.hiddenCardPath) &&
          score >= 400) {
        await player.play(AssetSource("voices/winner.mp3"));
        await _saveStatsIfNeeded();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isTablet = size.shortestSide >= 600;

    final crossAxisCount = isLandscape ? 4 : 3;

    return Scaffold(
      backgroundColor: AppColors.Lpink,
      appBar: AppBar(
        foregroundColor: AppColors.black,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.Lpink,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: isTablet ? 12 : 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _scoreBoardMini(
                        "المحاولات",
                        "$tries",
                        isTablet: isTablet,
                      ),
                      SizedBox(width: isTablet ? 14 : 8),
                      _scoreBoardMini(
                        "النتيجة",
                        "$score",
                        isTablet: isTablet,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: LayoutBuilder(
                      builder: (context, gridConstraints) {
                        final crossAxisSpacing = isTablet ? 14.0 : 8.0;
                        final mainAxisSpacing = isTablet ? 14.0 : 8.0;
                        final rowCount =
                            (_gameLogic.gameImg.length / crossAxisCount).ceil();
                        final tileWidth = (gridConstraints.maxWidth -
                                crossAxisSpacing * (crossAxisCount - 1)) /
                            crossAxisCount;
                        final tileHeight = (gridConstraints.maxHeight -
                                mainAxisSpacing * (rowCount - 1)) /
                            rowCount;
                        final aspect = tileWidth / tileHeight;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _gameLogic.gameImg.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: crossAxisSpacing,
                            mainAxisSpacing: mainAxisSpacing,
                            childAspectRatio: aspect,
                          ),
                          itemBuilder: (context, index) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _onCardTap(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: AppColors.crimson,
                                  image: DecorationImage(
                                    image:
                                        AssetImage(_gameLogic.gameImg[index]),
                                    fit: BoxFit.contain,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.crimson.withOpacity(0.30),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _scoreBoardMini(
  String title,
  String info, {
  required bool isTablet,
}) {
  return Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 10 : 6,
        horizontal: isTablet ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PrimaryText(
            text: title,
            fontWeight: FontWeight.w800,
            size: isTablet ? 18 : 14,
          ),
          SizedBox(height: isTablet ? 6 : 4),
          PrimaryText(
            text: info,
            fontWeight: FontWeight.w800,
            size: isTablet ? 18 : 14,
          ),
        ],
      ),
    ),
  );
}

class GameLogic {
  final String hiddenCardPath = 'assets/games/memo/hidden.png';
  late List<String> gameImg;

  // 8 cards
  final int cardCount = 8;

  final List<String> cardList1 = [
    "assets/games/memo/circle.png",
    "assets/games/memo/triangle.png",
    "assets/games/memo/heart.png",
    "assets/games/memo/star.png",
  ];

  final List<String> cardList2 = [
    "assets/games/memo/circle.png",
    "assets/games/memo/triangle.png",
    "assets/games/memo/heart.png",
    "assets/games/memo/star.png",
  ];

  List<String> cardsList = [];
  List<Map<int, String>> matchCheck = [];

  void initGame() {
    final temp = <String>[];
    temp.addAll(cardList1);
    temp.addAll(cardList2);
    temp.shuffle(Random());

    cardsList = temp;
    gameImg = List.generate(cardCount, (_) => hiddenCardPath);
    matchCheck.clear();
  }
}
