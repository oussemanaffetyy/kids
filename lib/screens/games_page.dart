import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_v1/constants.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> with TickerProviderStateMixin {
  late final AnimationController _enter; // entry drop
  late final AnimationController _loop;  // infinite floating

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

    // entry then start loop
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

  // staggered entry per item
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    final backgroundPath = isTablet
        ? 'assets/images/gamepage.png'
        : 'assets/images/gamepagePhone.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;

          final left = w * 0.18;
          final right = w * 0.18;
          final top = h * 0.16;  
          final height = isTablet ? h * 0.55 : h * 0.50;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(backgroundPath, fit: BoxFit.cover),
              ),

              Positioned(
                left: left,
                right: right,
                top: top,
                height: height,
                child: SafeArea(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: GamesList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 4 : 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final item = GamesList[index];

                      return FadeTransition(
                        opacity: _enterFade(index),
                        child: SlideTransition(
                          position: _enterSlide(index),
                          child: _FloatingGameTile(
                            loop: _loop,
                            index: index,
                            imagePath: item['imagePath'] as String,
                            title: item['GameName'] as String,
                            onTap: () {
                              if (index < gamesRoutes.length) {
                                Navigator.pushNamed(
                                  context,
                                  gamesRoutes[index]['routePath'] as String,
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingGameTile extends StatefulWidget {
  final AnimationController loop;
  final int index;
  final String imagePath;
  final String title;
  final VoidCallback onTap;

  const _FloatingGameTile({
    required this.loop,
    required this.index,
    required this.imagePath,
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
    return AnimatedBuilder(
      animation: widget.loop,
      builder: (context, child) {
        final v = widget.loop.value; // 0..1
        final phase = (widget.index * 0.17) % 1.0;

        final drift = ((v + phase) % 1.0);
        final dx = (drift * 8.0) - 4.0; // -4..+4

        final t = (v * 2 * math.pi) + (widget.index * 0.9);
        final dy = math.sin(t) * 3.0;

        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          scale: _pressed ? 0.97 : 1,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.85), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E212D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
