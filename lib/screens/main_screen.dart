import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:project_v1/constants.dart';
import 'package:project_v1/screens/loading_screen.dart';
import 'package:project_v1/services/student_store.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<void> _showLoadingAndNavigate(String route) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LoadingScreen(),
      ),
    );
    if (!mounted) return;
    await Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final size = ScreenSize(context);
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final backgroundPath = isTablet
        ? 'assets/images/Tab2.png'
        : 'assets/images/Phone.png';
    final phoneLift =
        isTablet ? 0.0 : -(size.height * 0.065).clamp(0.0, 48.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        _Header(),
                        SizedBox(height: size.height * (isTablet ? 0.14 : 0.0)),
                        Transform.translate(
                          offset: Offset(0, phoneLift),
                          child: _CategoriesGrid(
                            onItemTap: _showLoadingAndNavigate,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 40,
            left: 10,
            child: _AdminButton(
              onActivate: () async {
                final navContext =
                    Navigator.of(context, rootNavigator: true).context;
                final code = await showDialog<String>(
                  context: navContext,
                  builder: (context) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: const Text('Code admin'),
                      content: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Code',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
                if (!mounted) return;
                if (code == '2026') {
                  await StudentStore.instance.hasStudents();
                  if (!mounted) return;
                  Navigator.pushNamed(context, '/Admin');
                } else if (code != null && code.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code incorrect')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminButton extends StatefulWidget {
  final Future<void> Function() onActivate;

  const _AdminButton({required this.onActivate});

  @override
  State<_AdminButton> createState() => _AdminButtonState();
}

class _AdminButtonState extends State<_AdminButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        debugPrint('Admin button tapped');
        widget.onActivate();
      },
      child: SizedBox(
        width: 52,
        height: 52,
        child: Image.asset(
          'assets/images/admin.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _Header extends StatefulWidget {
  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _showStars = false;
  static final AudioPlayer _tapPlayer = AudioPlayer();
  static bool _tapPlayerReady = false;

  Future<void> _startTapFx() async {
    if (!_tapPlayerReady) {
      await _tapPlayer.setReleaseMode(ReleaseMode.stop);
      await _tapPlayer.setVolume(0.7);
      _tapPlayerReady = true;
    }
    _tapPlayer.play(AssetSource('voices/tap_click.mp3'));
    if (mounted) {
      setState(() => _showStars = true);
    }
    await Future.delayed(const Duration(milliseconds: 420));
    if (mounted) {
      setState(() => _showStars = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = ScreenSize(context);
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final headerHeight = (size.height * 0.26).clamp(170.0, 240.0).toDouble();
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final avatarSize = (shortestSide * (isTablet ? 0.28 : 0.24))
        .clamp(90.0, 170.0)
        .toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: headerHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 18,
              top: 16,
              child: Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 22,
              top: 28,
              child: Container(
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTapDown: (_) => _startTapFx(),
                      child: Transform.translate(
                        offset: Offset(0, isTablet ? 240 : 130),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: avatarSize,
                            width: avatarSize,
                            child: Lottie.asset(
                              'assets/json/avatar.json',
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
                          if (_showStars)
                            IgnorePointer(
                              child: Lottie.asset(
                                'assets/json/stars.json',
                                width: avatarSize * 1.2,
                                height: avatarSize * 1.2,
                                fit: BoxFit.contain,
                                repeat: false,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  final Future<void> Function(String route) onItemTap;

  const _CategoriesGrid({required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 4;
    const childAspectRatio = 0.9;
    const colors = [
      Color(0xFF4DA3FF), // معرفية
      Color(0xFF6DD96C), // لغوية
      Color(0xFFFFD45A), // حركية
      Color(0xFFFF6B6B), // اجتماعية-انفعالية
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        itemCount: CardsList.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemBuilder: (context, index) {
          final item = CardsList[index];
          return _CategoryCard(
            imagePath: item['imagePath'].toString(),
            color: colors[index % colors.length],
            onTap: () {
              onItemTap(routesList[index]['routePath'].toString());
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String imagePath;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.imagePath,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _showStars = false;
  static final AudioPlayer _tapPlayer = AudioPlayer();
  static bool _tapPlayerReady = false;
  late final AnimationController _floatController;
  late final Animation<double> _floatY;
  late final Animation<double> _rotateZ;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _floatY = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _rotateZ = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _startTapFx() async {
    if (!_tapPlayerReady) {
      await _tapPlayer.setReleaseMode(ReleaseMode.stop);
      await _tapPlayer.setVolume(0.7);
      _tapPlayerReady = true;
    }
    _tapPlayer.play(AssetSource('voices/tap_click.mp3'));
    if (mounted) {
      setState(() => _showStars = true);
    }
  }

  Future<void> _finishTapAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 420));
    if (mounted) {
      setState(() => _showStars = false);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _startTapFx();
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () {
        setState(() => _pressed = false);
        setState(() => _showStars = false);
      },
      onTap: _finishTapAndNavigate,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.98 : 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
            final base = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
            final circleSize = base * (isTablet ? 0.72 : 0.50);
            final overlaySize = circleSize * 1.25;
            return AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatY.value),
                  child: Transform.rotate(
                    angle: _rotateZ.value,
                    child: child,
                  ),
                );
              },
              child: Center(
                child: SizedBox(
                  width: overlaySize,
                  height: overlaySize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: circleSize,
                        height: circleSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.color,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 10,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: ClipOval(
                              child: Image.asset(
                                widget.imagePath,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_showStars)
                        IgnorePointer(
                          child: Lottie.asset(
                            'assets/json/stars.json',
                            width: overlaySize,
                            height: overlaySize,
                            fit: BoxFit.contain,
                            repeat: false,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GamesCard extends StatefulWidget {
  @override
  State<_GamesCard> createState() => _GamesCardState();
}

class _GamesCardState extends State<_GamesCard> {
  Color color = AppColors.yellow;

  @override
  Widget build(BuildContext context) {
    final size = ScreenSize(context);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        setState(() {
          color = color == AppColors.yellow ? AppColors.crimson : AppColors.yellow;
        });
        Navigator.pushNamed(context, '/Games');
      },
      child: Container(
        height: 120,
        width: size.width * 0.92,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: color,
          border: Border.all(
            color: Colors.white.withOpacity(0.8),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Image.asset(
                "assets/games.png",
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: PrimaryText(
                  text: "الألعاب",
                  fontWeight: FontWeight.w800,
                  size: 18,
                  color: AppColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
