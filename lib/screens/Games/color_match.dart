import 'package:flutter/material.dart';
import 'package:project_v1/constants.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'package:project_v1/services/stats_store.dart';

class ColorMatch extends StatefulWidget {
  _ColorMatchState createState() => _ColorMatchState();
}

class _ColorMatchState extends State<ColorMatch> {
  final player = AudioPlayer();
  final Map<String, bool> score = {};
  final Map choices = {
    '🍏': Colors.green,
    '🍋': Colors.yellow,
    '🍅': Colors.red,
    '🍇': Colors.purple,
    '🥥': Colors.brown,
    '🥕': Colors.orange
  };

  int seed = 0;
  int _errors = 0;
  int _correct = 0;
  DateTime _startedAt = DateTime.now();
  bool _saved = false;
  bool _hasPlayed = false;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    return Scaffold(
      backgroundColor: AppColors.sage,
      appBar: AppBar(
          foregroundColor: AppColors.black,
          automaticallyImplyLeading: false,
          centerTitle: true,
          
          elevation: 0,
          backgroundColor: AppColors.sage),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gap = isTablet ? 12.0 : 6.0;
          final availableHeight = constraints.maxHeight;
          final itemHeight =
              ((availableHeight - gap * (choices.length - 1)) / choices.length)
                  .clamp(isTablet ? 60.0 : 34.0, isTablet ? 88.0 : 52.0);
          final itemWidth = isTablet ? 200.0 : 120.0;
          final emojiSize = itemHeight * 0.6;

          final emojiList = choices.keys.toList();

          final targets = List.generate(emojiList.length, (index) {
            final emoji = emojiList[index];
            final isLast = index == emojiList.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : gap),
              child: _buildDragTarget(
                emoji,
                width: itemWidth,
                height: itemHeight,
                fontSize: isTablet ? 22 : 18,
              ),
            );
          })
            ..shuffle(Random(seed));

          final draggables = List.generate(emojiList.length, (index) {
            final emoji = emojiList[index];
            final isLast = index == emojiList.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : gap),
              child: Draggable<String>(
                data: emoji,
                child: Emoji(
                  emoji: score[emoji] == true ? '✅' : emoji,
                  size: emojiSize,
                  boxHeight: itemHeight,
                  boxWidth: itemWidth,
                ),
                feedback: Emoji(
                  emoji: emoji,
                  size: emojiSize,
                  boxHeight: itemHeight,
                  boxWidth: itemWidth,
                ),
                childWhenDragging: Emoji(
                  emoji: '🌱',
                  size: emojiSize,
                  boxHeight: itemHeight,
                  boxWidth: itemWidth,
                ),
              ),
            );
          });

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: targets,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: draggables,
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildDragTarget(
    emoji, {
    required double width,
    required double height,
    required double fontSize,
  }) {
    return DragTarget<String>(
        builder: (BuildContext context, List<String?> incoming, List rejected) {
          if (score[emoji] == true) {
            return Container(
              child: PrimaryText(
                  text: "أحسنت", fontWeight: FontWeight.w800, size: fontSize),
              alignment: Alignment.center,
              height: height,
              width: width,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 2,
                    )
                  ]),
            );
          } else {
            return Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: choices[emoji],
                  boxShadow: [
                    BoxShadow(
                      color: choices[emoji],
                      blurRadius: 2,
                    )
                  ]),
            );
          }
        },
        onWillAccept: (data) => data == emoji,
        onAccept: (data) {
          setState(
            () {
              score[emoji] = true;
              _hasPlayed = true;
              _correct += 1;
              player.play(AssetSource("voices/correct.mp3"));
              if (score.length == 6) {
                player.play(AssetSource("voices/winner.mp3"));
                _saveStatsIfNeeded();
                Future.delayed(
                  Duration(seconds: 4),
                  () {
                    setState(() => score.clear());
                    setState(() => seed++);
                    setState(() {
                      _errors = 0;
                      _correct = 0;
                      _saved = false;
                      _hasPlayed = false;
                      _startedAt = DateTime.now();
                    });
                  },
                );
              }
            },
          );
        },
        onLeave: (data) {
          Vibration.vibrate(duration: 500);
          setState(() => _hasPlayed = true);
          setState(() => _errors += 1);
        });
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
        gameKey: 'color',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
    super.dispose();
  }
}

class Emoji extends StatelessWidget {
  final String emoji;
  final double size;
  final double boxHeight;
  final double boxWidth;
  Emoji({
    required this.emoji,
    required this.size,
    required this.boxHeight,
    required this.boxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: boxHeight,
        width: boxWidth,
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(color: AppColors.black, fontSize: size),
          ),
        ),
      ),
    );
  }
}
