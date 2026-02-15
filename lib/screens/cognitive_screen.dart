import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_v1/screens/loading_screen.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final avatarSize = isTablet ? 170.0 : 140.0;
    final gamesLift = avatarSize - (isTablet ? 20.0 : 10.0);
    final backgroundPath = isTablet
        ? 'assets/images/bgtablet.png'
        : 'assets/images/bgphone.png';

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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: isTablet ? size.width * 0.80 : size.width * 0.86,
                        child: GridView.builder(
                          itemCount: _cognitiveItems.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 0,
                            mainAxisSpacing: 0,
                            childAspectRatio: 1.08,
                          ),
                          itemBuilder: (context, index) {
                            final item = _cognitiveItems[index];
                            return _CognitiveCard(
                              imagePath: item.imagePath,
                              title: item.title,
                              accentColor:
                                  _cardAccents[index % _cardAccents.length],
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (_) => const LoadingScreen(),
                                  ),
                                );
                                if (!context.mounted) return;
                                await Navigator.pushNamed(context, item.routePath);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: SizedBox(
              width: avatarSize,
              height: avatarSize,
              child: _AvatarGamesBadge(isTablet: isTablet),
            ),
          ),
          Positioned(
            bottom: 12 + gamesLift,
            right: 12,
            child: _GamesBadge(isTablet: isTablet),
          ),
        ],
      ),
    );
  }
}

class _CognitiveCard extends StatefulWidget {
  final String imagePath;
  final String title;
  final Color accentColor;
  final VoidCallback onTap;

  const _CognitiveCard({
    required this.imagePath,
    required this.title,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_CognitiveCard> createState() => _CognitiveCardState();
}

class _CognitiveCardState extends State<_CognitiveCard>
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
    _floatY = Tween<double>(begin: -3, end: 3).animate(
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
            final cardSize = base * (isTablet ? 0.58 : 0.64);
            final labelHeight = isTablet ? 32.0 : 28.0;
            final overlaySize = cardSize * 1.2;
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: overlaySize,
                      height: overlaySize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: cardSize,
                            height: cardSize,
                            child: Container(
                          padding: EdgeInsets.all(isTablet ? 14 : 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: widget.accentColor.withOpacity(0.25),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                widget.imagePath,
                                fit: BoxFit.contain,
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
                    SizedBox(height: isTablet ? 4 : 2),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: SizedBox(
                        width: cardSize,
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            height: labelHeight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: widget.accentColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: widget.accentColor.withOpacity(0.9),
                                width: 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x15000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.title,
                                style: GoogleFonts.almarai(
                                  fontSize: isTablet ? 18 : 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AvatarGamesBadge extends StatefulWidget {
  final bool isTablet;

  const _AvatarGamesBadge({required this.isTablet});

  @override
  State<_AvatarGamesBadge> createState() => _AvatarGamesBadgeState();
}

class _AvatarGamesBadgeState extends State<_AvatarGamesBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatY;
  late final Animation<double> _rotateZ;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatY = Tween<double>(begin: -2, end: 2).animate(
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

  @override
  Widget build(BuildContext context) {
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
      child: IgnorePointer(
        child: Lottie.asset(
          'assets/json/avatar.json',
          fit: BoxFit.contain,
          repeat: true,
        ),
      ),
    );
  }
}

class _GamesBadge extends StatefulWidget {
  final bool isTablet;

  const _GamesBadge({required this.isTablet});

  @override
  State<_GamesBadge> createState() => _GamesBadgeState();
}

class _GamesBadgeState extends State<_GamesBadge>
    with SingleTickerProviderStateMixin {
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
    _floatY = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _rotateZ = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeSize = widget.isTablet ? 76.0 : 64.0;
    final hitSize = badgeSize + 24;
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
      child: IgnorePointer(
        child: SizedBox(
          width: hitSize,
          height: hitSize + 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: badgeSize,
                width: badgeSize,
                child: Lottie.asset(
                  'assets/json/stars.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}


class _CognitiveItem {
  final String title;
  final String imagePath;
  final String routePath;

  const _CognitiveItem({
    required this.title,
    required this.imagePath,
    required this.routePath,
  });
}

const _cognitiveItems = [
  _CognitiveItem(
    title: 'الأرقام',
    imagePath: 'assets/cognitive/numbers.png',
    routePath: '/Nums',
  ),
  _CognitiveItem(
    title: 'الحروف',
    imagePath: 'assets/cognitive/letters.png',
    routePath: '/Letters',
  ),
  _CognitiveItem(
    title: 'الحيوانات',
    imagePath: 'assets/cognitive/animals.png',
    routePath: '/Animals',
  ),
  _CognitiveItem(
    title: 'العائلة',
    imagePath: 'assets/cognitive/family.png',
    routePath: '/Family',
  ),
  _CognitiveItem(
    title: 'الفواكه',
    imagePath: 'assets/cognitive/fruits.png',
    routePath: '/Fruits',
  ),
  _CognitiveItem(
    title: 'الخضروات',
    imagePath: 'assets/cognitive/vegetables.png',
    routePath: '/Vegetables',
  ),
];

const _cardAccents = [
  Color(0xFF4DA3FF),
  Color(0xFF6FD28A),
  Color(0xFFFFC857),
  Color(0xFFF47A7A),
  Color(0xFF8B7CFF),
  Color(0xFF2EC4B6),
];
