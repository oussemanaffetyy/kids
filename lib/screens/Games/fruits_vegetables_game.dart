import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/services/stats_store.dart';

class FruitsVegetablesGame extends StatefulWidget {
  const FruitsVegetablesGame({super.key});

  @override
  State<FruitsVegetablesGame> createState() => _FruitsVegetablesGameState();
}

class _FruitsVegetablesGameState extends State<FruitsVegetablesGame>
    with TickerProviderStateMixin {
  final AudioPlayer _tapPlayer = AudioPlayer();
  final Random _random = Random();

  int _level = 1;
  int _score = 0;
  int _levelStars = 0;
  List<_Item> _items = [];
  final Set<String> _matched = {};
  bool _showStarsFruits = false;
  bool _showStarsVeg = false;
  bool _lockInput = false;
  String? _wrongItemPath;
  int _errors = 0;
  int _correct = 0;
  DateTime _startedAt = DateTime.now();
  bool _saved = false;
  bool _hasPlayed = false;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  String? _shakeBasket; // 'fruit' | 'veg'
  late final AnimationController _floatCtrl;

  static const List<String> _fruitItems = [
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

  static const List<String> _vegetableItems = [
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Beans.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Beetroot.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-BitterGourd.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Brinjal.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Cabbage.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Capsicum.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Carrot.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Cauliflower.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Chilli.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Corn.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Cucumber.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Garlic.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Onion.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Potato.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Radish.png',
    'assets/games/VegetablesetFruits/Vegetables/Vegetables-Tomato.png',
  ];

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
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
      duration: const Duration(milliseconds: 2400),
    )..repeat();
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

  void _startLevel() {
    final fruitCount = _level == 1 ? 2 : (_level == 2 ? 3 : 4);
    final vegCount = _level == 1 ? 2 : (_level == 2 ? 3 : 4);

    final fruits = [..._fruitItems]..shuffle(_random);
    final vegs = [..._vegetableItems]..shuffle(_random);

    final picks = <_Item>[];
    for (var i = 0; i < fruitCount; i++) {
      picks.add(_Item(path: fruits[i], type: _ItemType.fruit));
    }
    for (var i = 0; i < vegCount; i++) {
      picks.add(_Item(path: vegs[i], type: _ItemType.veg));
    }

    picks.shuffle(_random);
    _items = picks;
    _matched.clear();
    _showStarsFruits = false;
    _showStarsVeg = false;
    _lockInput = false;
    _wrongItemPath = null;
    _hasPlayed = false;
    _startedAt = DateTime.now();
    _saved = false;
    setState(() {});
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
        gameKey: 'fruits_veg',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  Future<void> _onAccepted(_Item item, _ItemType targetType) async {
    if (_lockInput) return;
    _lockInput = true;
    _hasPlayed = true;

    if (item.type == targetType) {
      await _tapPlayer.play(AssetSource('voices/tap_click.mp3'));
      setState(() {
        _matched.add(item.path);
        _score += 1;
        _correct += 1;
        if (targetType == _ItemType.fruit) {
          _showStarsFruits = true;
        } else {
          _showStarsVeg = true;
        }
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _showStarsFruits = false;
        _showStarsVeg = false;
      });

      if (_matched.length == _items.length) {
        if (_level >= 3) {
          await _saveStatsIfNeeded();
        }
        await _showLevelDialog();
        return;
      }
      _lockInput = false;
    } else {
      _shakeBasket = targetType == _ItemType.fruit ? 'fruit' : 'veg';
      _wrongItemPath = item.path;
      _errors += 1;
      _shakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _shakeBasket = null;
        _wrongItemPath = null;
      });
      _lockInput = false;
    }
  }

  Future<void> _showLevelDialog() async {
    if (!mounted) return;
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
                Text(
                  isLast ? 'أحسنت!' : 'ممتاز!',
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
      _score = 0;
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
    final draggableSize =
        (size.shortestSide * (isTablet ? 0.18 : 0.16)).clamp(50.0, 120.0);

    const backgroundPath = 'assets/gamenumbers/bg.png';
    const fruitsBasket = 'assets/games/VegetablesetFruits/Fruits/Fruits.png';
    const vegBasket =
        'assets/games/VegetablesetFruits/Vegetables/Vegetables.png';

    final basketWidth =
        (isTablet ? size.width * 0.26 : size.width * 0.22).clamp(90.0, 210.0);
    final basketLabelSize = isTablet ? 18.0 : 14.0;
    final basketsGap = isTablet ? 24.0 : 12.0;
    final itemsGap = isTablet ? 12.0 : 8.0;

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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _BasketTarget(
                            label: 'فواكه',
                            imagePath: fruitsBasket,
                            width: basketWidth,
                            labelSize: basketLabelSize,
                            showStars: _showStarsFruits,
                            shake: _shakeBasket == 'fruit',
                            shakeAnim: _shakeAnim,
                            onAccept: (item) =>
                                _onAccepted(item, _ItemType.fruit),
                          ),
                          SizedBox(width: basketsGap),
                          _BasketTarget(
                            label: 'خضروات',
                            imagePath: vegBasket,
                            width: basketWidth,
                            labelSize: basketLabelSize,
                            showStars: _showStarsVeg,
                            shake: _shakeBasket == 'veg',
                            shakeAnim: _shakeAnim,
                            onAccept: (item) =>
                                _onAccepted(item, _ItemType.veg),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 20 : 8),
                      Wrap(
                        spacing: itemsGap,
                        runSpacing: itemsGap,
                        alignment: WrapAlignment.center,
                        children: _items
                            .where((item) => !_matched.contains(item.path))
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Draggable<_Item>(
                            data: item,
                            feedback: SizedBox(
                              width: draggableSize,
                              height: draggableSize,
                              child:
                                  Image.asset(item.path, fit: BoxFit.contain),
                            ),
                            childWhenDragging: SizedBox(
                              width: draggableSize,
                              height: draggableSize,
                            ),
                            child: AnimatedBuilder(
                              animation: _floatCtrl,
                              builder: (context, child) {
                                final t = _floatCtrl.value * 2 * pi;
                                final dx = sin(t + index) * 2.0;
                                final dy = cos(t + index * 0.7) * 2.0;
                                return Transform.translate(
                                  offset: Offset(dx, dy),
                                  child: child,
                                );
                              },
                              child: Container(
                                width: draggableSize,
                                height: draggableSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: item.path == _wrongItemPath
                                      ? Border.all(
                                          color: Colors.redAccent,
                                          width: 3,
                                        )
                                      : null,
                                ),
                                child: Image.asset(
                                  item.path,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BasketTarget extends StatelessWidget {
  final String label;
  final String imagePath;
  final double width;
  final double labelSize;
  final bool showStars;
  final bool shake;
  final Animation<double> shakeAnim;
  final ValueChanged<_Item> onAccept;

  const _BasketTarget({
    required this.label,
    required this.imagePath,
    required this.width,
    required this.labelSize,
    required this.showStars,
    required this.shake,
    required this.shakeAnim,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_Item>(
      onWillAccept: (data) => data != null,
      onAccept: onAccept,
      builder: (context, candidates, rejects) {
        return AnimatedBuilder(
          animation: shakeAnim,
          builder: (context, child) {
            final dx = shake ? shakeAnim.value : 0.0;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: child,
            );
          },
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.almarai(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E212D),
                ),
              ),
              const SizedBox(height: 6),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: width,
                    height: width,
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  ),
                  if (showStars)
                    Lottie.asset(
                      'assets/json/stars.json',
                      width: width * 0.9,
                      height: width * 0.9,
                      repeat: false,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _ItemType { fruit, veg }

class _Item {
  final String path;
  final _ItemType type;

  const _Item({required this.path, required this.type});
}
