import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class CategoryGamesPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> games;

  const CategoryGamesPage({
    super.key,
    required this.title,
    required this.games,
  });

  @override
  State<CategoryGamesPage> createState() => _CategoryGamesPageState();
}

class _CategoryGamesPageState extends State<CategoryGamesPage>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _enter.forward().whenComplete(() {
      if (mounted) _loop.repeat();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _loop.dispose();
    super.dispose();
  }

  Animation<double> _enterFade(int i) {
    final start = (i * 0.06).clamp(0.0, 0.75);
    final end = (start + 0.35).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _enter,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _enterSlide(int i) {
    final start = (i * 0.06).clamp(0.0, 0.75);
    final end = (start + 0.45).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    return Tween<Offset>(
      begin: const Offset(0.0, -0.35),
      end: const Offset(0.06, 0.0),
    ).animate(curved);
  }

  Animation<double> _headerFade() {
    return CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final isCognitive = widget.title == 'المعرفية';
    final isLinguistic = widget.title == 'اللغوية';
    final isMotor = widget.title == 'الحركية';
    final isSocial = widget.title == 'الاجتماعية والانفعالية' ||
        widget.title == 'الاجتماعية';
    final backgroundPath = isTablet
        ? 'assets/images/gamepage.png'
        : 'assets/images/gamepagePhone.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final crossAxisSpacing = isTablet ? 10.0 : 3.0;
          final mainAxisSpacing = isTablet ? 10.0 : 3.0;
          final count = widget.games.length;
          final crossAxisCount = isTablet
              ? (count == 1
                  ? 1
                  : (count == 2
                      ? 2
                      : 3))
              : (count == 1
                  ? 1
                  : (count >= 4 ? 3 : 2));
          final maxExtent = isTablet ? 280.0 : 110.0;
          final tileExtent = isTablet ? 220.0 : 122.0;
          final categoryColor = isCognitive
              ? const Color(0xFF6CB5FF)
              : isLinguistic
                  ? const Color(0xFF6FD28A)
                  : isMotor
                      ? const Color(0xFFF7C86A)
                      : const Color(0xFFF47A7A);
          final headerTitle = widget.title;
          final headerLine = isCognitive
              ? 'الكفاءة المعرفية'
              : isLinguistic
                  ? 'الكفاءة اللغوية'
                  : isMotor
                      ? 'الكفاءة الحركية'
                      : 'الكفاءة الاجتماعية';

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(backgroundPath, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _headerFade(),
                      child: CategoryHeader(
                        title: headerTitle,
                        line: headerLine,
                        color: categoryColor,
                        subtitle: 'اختر نشاطًا',
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, gridC) {
                          final horizontalPad = isTablet ? w * 0.06 : 4.0;
                          final topPad = isTablet ? 26.0 : 0.0;
                          final bottomPad = isTablet ? 18.0 : 0.0;
                          final naturalGridWidth =
                              maxExtent * crossAxisCount +
                                  crossAxisSpacing * (crossAxisCount - 1);
                          final phoneWidthFactor = count <= 2
                              ? 0.72
                              : (count <= 4 ? 0.84 : 0.9);
                          final maxGridWidth = isTablet
                              ? math.min(gridC.maxWidth, naturalGridWidth)
                              : math.min(
                                  gridC.maxWidth * phoneWidthFactor,
                                  naturalGridWidth,
                                );
                          final rowCount = math.max(
                            1,
                            (widget.games.length / crossAxisCount).ceil(),
                          );
                          final usablePhoneHeight = math.max(
                            0.0,
                            gridC.maxHeight -
                                topPad -
                                bottomPad -
                                mainAxisSpacing * (rowCount - 1),
                          );
                          final effectiveTileExtent = isTablet
                              ? tileExtent
                              : (usablePhoneHeight / rowCount).clamp(69.0, 90.0);
                          final gridDelegate = isTablet
                              ? SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: maxExtent,
                                  mainAxisExtent: effectiveTileExtent,
                                  crossAxisSpacing: crossAxisSpacing,
                                  mainAxisSpacing: mainAxisSpacing,
                                )
                              : SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisExtent: effectiveTileExtent,
                                  crossAxisSpacing: crossAxisSpacing,
                                  mainAxisSpacing: mainAxisSpacing,
                                );
                          return Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: maxGridWidth),
                              child: GridView.builder(
                                physics: isTablet
                                    ? const BouncingScrollPhysics()
                                    : const NeverScrollableScrollPhysics(),
                                itemCount: widget.games.length,
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPad,
                                  topPad,
                                  horizontalPad,
                                  bottomPad,
                                ),
                                gridDelegate: gridDelegate,
                                itemBuilder: (context, index) {
                                  final item = widget.games[index];
                                  final imagePath =
                                      item['imagePath'] as String?;
                                  final lottiePath =
                                      item['lottiePath'] as String?;
                                  final title = item['title'] as String;
                                  final route = item['route'] as String;

                                  return FadeTransition(
                                    opacity: _enterFade(index),
                                    child: SlideTransition(
                                      position: _enterSlide(index),
                                      child: _FloatingGameTile(
                                        loop: _loop,
                                        index: index,
                                        imagePath: imagePath,
                                        lottiePath: lottiePath,
                                        categoryColor: categoryColor,
                                        title: title,
                                        onTap: () {
                                          Navigator.pushNamed(context, route);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.title == 'المعرفية')
                Positioned(
                  bottom: isTablet ? 100 : 74,
                  right: isTablet ? 18 : 12,
                  child: _LearnBadge(
                    isTablet: isTablet,
                    onTap: () {
                      Navigator.pushNamed(context, '/CognitiveLearn');
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LearnBadge extends StatefulWidget {
  final bool isTablet;
  final VoidCallback onTap;

  const _LearnBadge({
    required this.isTablet,
    required this.onTap,
  });

  @override
  State<_LearnBadge> createState() => _LearnBadgeState();
}

class _LearnBadgeState extends State<_LearnBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isTablet ? 150.0 : 122.0;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isTablet ? 10 : 8,
                vertical: widget.isTablet ? 8 : 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFF0A8).withOpacity(0.55),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: size,
                    width: size,
                    child: Lottie.asset(
                      'assets/json/learn.json',
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'التعلّم',
                    style: TextStyle(
                      fontSize: widget.isTablet ? 14 : 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E212D),
                      shadows: const [
                        Shadow(
                          color: Color(0x22000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingGameTile extends StatefulWidget {
  final AnimationController loop;
  final int index;
  final String? imagePath;
  final String? lottiePath;
  final Color categoryColor;
  final String title;
  final VoidCallback onTap;

  const _FloatingGameTile({
    required this.loop,
    required this.index,
    required this.imagePath,
    required this.lottiePath,
    required this.categoryColor,
    required this.title,
    required this.onTap,
  });

  @override
  State<_FloatingGameTile> createState() => _FloatingGameTileState();
}

class _FloatingGameTileState extends State<_FloatingGameTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final maxW = constraints.maxWidth;
        final pad = isTablet ? 10.0 : 3.0;
        final availableH = math.max(0.0, maxH - pad * 2);
        final availableW = math.max(0.0, maxW - pad * 2);
        final spacing = isTablet ? 6.0 : 1.0;
        final labelHeight = isTablet ? 30.0 : 17.5;
        final availableForImage =
            math.max(0.0, availableH - labelHeight - spacing);
        final imageBox =
            math.max(0.0, math.min(availableW, availableForImage));
        const radius = 26.0;
        final baseScale = isTablet ? 0.92 : 0.90;
        final labelMaxWidth =
            math.min(isTablet ? 140.0 : 86.0, availableW);
        final contentW = maxW;
        final contentH = maxH;

        final cardBg =
            Color.lerp(Colors.white, widget.categoryColor, 0.08)!;
        final cardBorder =
            Color.lerp(const Color(0xFFE9EEF6), widget.categoryColor, 0.12)!;

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            scale: _pressed ? baseScale * 0.96 : baseScale,
            child: Center(
              child: SizedBox(
                width: contentW,
                height: contentH,
                child: Container(
                  padding: EdgeInsets.all(pad),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: cardBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 14,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            height: imageBox,
                            width: imageBox,
                            child: widget.lottiePath != null
                                ? Lottie.asset(
                                    widget.lottiePath!,
                                    fit: BoxFit.contain,
                                    repeat: true,
                                  )
                                : Image.asset(
                                    widget.imagePath!,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing),
                      Container(
                        height: labelHeight,
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 9 : 5,
                          vertical: isTablet ? 2 : 1,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: labelMaxWidth,
                        ),
                        decoration: BoxDecoration(
                          color: widget.categoryColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: widget.categoryColor.withOpacity(0.9),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.almarai(
                                fontSize: isTablet ? 12.5 : 9.4,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CategoryHeader extends StatelessWidget {
  final String title;
  final String line;
  final String subtitle;
  final Color color;

  const CategoryHeader({
    super.key,
    required this.title,
    required this.line,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    return Padding(
      padding: EdgeInsets.only(
        top: isTablet ? 10 : 8,
        bottom: isTablet ? 12 : 10,
      ),
      child: Column(
        children: [
          Text(
            line,
            textAlign: TextAlign.center,
            style: GoogleFonts.almarai(
              fontSize: isTablet ? 26 : 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.almarai(
              fontSize: isTablet ? 15 : 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8A94A6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            width: isTablet ? 240 : 200,
            color: color.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
