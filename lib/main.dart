import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:project_v1/constants.dart';
import 'package:project_v1/screens/Games/memory.dart';
import 'package:project_v1/screens/Games/numbers_game.dart';
import 'package:project_v1/screens/Games/letters_game.dart';
import 'package:project_v1/screens/Games/letters_quiz_game.dart';
import 'package:project_v1/screens/Games/family_game.dart';
import 'package:project_v1/screens/Games/fruits_vegetables_game.dart';
import 'package:project_v1/screens/Games/puzzle_game.dart';
import 'package:project_v1/screens/Games/listen_name_game.dart';
import 'package:project_v1/screens/Games/word_build_game.dart';
import 'package:project_v1/games/tracing_game.dart';
import 'package:project_v1/games/tap_target_game.dart';
import 'package:project_v1/games/emotion_game.dart';
import 'package:project_v1/games/compare_game.dart';
import 'package:project_v1/screens/animals_screen.dart';
import 'package:project_v1/screens/family_screen.dart';
import 'package:project_v1/screens/splash_screen.dart';
import 'package:project_v1/screens/main_screen.dart';
import 'package:project_v1/screens/nums_screen.dart';
import 'package:project_v1/screens/letters_screen.dart';
import 'package:project_v1/screens/Games/color_match.dart';
import 'package:project_v1/screens/games_screen.dart';
import 'package:project_v1/screens/fruits_screen.dart';
import 'package:project_v1/screens/vegetables_screen.dart';
import 'package:project_v1/services/audio_controller.dart';
import 'package:project_v1/screens/cognitive_screen.dart';
import 'package:project_v1/screens/admin_screen.dart';
import 'package:project_v1/screens/games_page.dart';
import 'package:project_v1/screens/category_games_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioPlayer.global.setAudioContext(
    AudioContextConfig(
      route: AudioContextConfigRoute.speaker,
      duckAudio: true,
      respectSilence: false,
      stayAwake: false,
    ).build(),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await _enterImmersiveMode();
  runApp(const MyApp());
}

Future<void> _enterImmersiveMode() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ValueNotifier<bool> _canPop = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _currentRoute = ValueNotifier<String?>(null);
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  late final _AppRouteObserver _routeObserver;
  Timer? _immersiveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AudioController.instance.init();
    _routeObserver = _AppRouteObserver(_canPop, _currentRoute);
    _reapplyImmersive(delay: Duration.zero);
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      if (systemOverlaysAreVisible) {
        _reapplyImmersive();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _immersiveTimer?.cancel();
    SystemChrome.setSystemUIChangeCallback(null);
    _canPop.dispose();
    _currentRoute.dispose();
    super.dispose();
  }

  void _reapplyImmersive({Duration delay = const Duration(milliseconds: 350)}) {
    _immersiveTimer?.cancel();
    _immersiveTimer = Timer(delay, () async {
      if (!mounted) return;
      await _enterImmersiveMode();
    });
  }

  @override
  void didChangeMetrics() {
    // Re-enter fullscreen after notification shade/system bars interactions.
    _reapplyImmersive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AudioController.instance.pause();
    } else if (state == AppLifecycleState.resumed) {
      AudioController.instance.resume();
      _reapplyImmersive(delay: const Duration(milliseconds: 180));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids App',
      theme: ThemeData(scaffoldBackgroundColor: AppColors.backGround),
      debugShowCheckedModeBanner: false,
      navigatorKey: _navKey,
      navigatorObservers: [_routeObserver],
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            ValueListenableBuilder<bool>(
              valueListenable: _canPop,
              builder: (context, canPop, _) {
                if (!canPop) return const SizedBox.shrink();
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 10,
                  child: _BackButtonIcon(
                    onTap: () => _navKey.currentState?.maybePop(),
                  ),
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 10,
              child: ValueListenableBuilder<bool>(
                valueListenable: AudioController.instance.isMusicOn,
                builder: (context, isOn, _) {
                  return _MusicToggleButton(
                    isOn: isOn,
                    onTap: AudioController.instance.toggleMusic,
                  );
                },
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _currentRoute,
              builder: (context, routeName, _) {
                const gameRoutes = {
                  '/Color',
                  '/Memory',
                  '/NumbersGame',
                  '/LettersGame',
                  '/LettersQuizGame',
                  '/ListenNameGame',
                  '/WordBuildGame',
                  '/TracingGame',
                  '/TapTargetGame',
                  '/EmotionGame',
                  '/CompareGame',
                  '/FamilyGame',
                  '/FruitsVegetablesGame',
                  '/PuzzlesGame',
                };
                if (routeName == null || !gameRoutes.contains(routeName)) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _ResetButton(
                          onTap: () {
                            final current = _currentRoute.value;
                            if (current == null) return;
                            _navKey.currentState?.pushReplacementNamed(current);
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      routes: {
        '/': (context) => SplashScreen(),
        '/Main': (context) => MainScreen(),
        '/Admin': (context) => const AdminScreen(),
        '/Cognitive': (context) => const LearningScreen(),
        '/GamesPage': (context) => const GamesPage(),
        '/CognitiveLearn': (context) => const LearningScreen(),
        '/CognitiveGames': (context) => const CategoryGamesPage(
              title: 'المعرفية',
              games: cognitiveGames,
            ),
        '/LinguisticGames': (context) => const CategoryGamesPage(
              title: 'اللغوية',
              games: linguisticGames,
            ),
        '/MotorGames': (context) => const CategoryGamesPage(
              title: 'الحركية',
              games: motorGames,
            ),
        '/SocialGames': (context) => const CategoryGamesPage(
              title: 'الاجتماعية والانفعالية',
              games: socialGames,
            ),
        '/Nums': (context) => NumsScreen(),
        '/Animals': (context) => AnimalScreen(),
        '/Letters': (context) => LettersScreen(),
        '/Family': (context) => FamilyScreen(),
        '/Games': (context) => GameScreen(),
        '/Color': (context) => ColorMatch(),
        '/Memory': (context) => Memory(),
        '/NumbersGame': (context) => const NumbersGame(),
        '/LettersGame': (context) => const LettersGame(),
        '/LettersQuizGame': (context) => const LettersQuizGame(),
        '/ListenNameGame': (context) => const ListenNameGame(),
        '/WordBuildGame': (context) => const WordBuildGame(),
        '/TracingGame': (context) => const TracingGame(),
        '/TapTargetGame': (context) => const TapTargetGame(),
        '/EmotionGame': (context) => const EmotionGame(),
        '/CompareGame': (context) => const CompareGame(),
        '/FamilyGame': (context) => const FamilyGame(),
        '/FruitsVegetablesGame': (context) => const FruitsVegetablesGame(),
        '/PuzzlesGame': (context) => const PuzzlesGame(),
        '/Fruits': (context) => Fruits(),
        '/Vegetables': (context) => Vegetables(),
      },
    );
  }
}

class _AppRouteObserver extends NavigatorObserver {
  final ValueNotifier<bool> canPop;
  final ValueNotifier<String?> currentRoute;

  _AppRouteObserver(this.canPop, this.currentRoute);

  void _notify() {
    canPop.value = navigator?.canPop() ?? false;
  }

  void _updateRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null) {
      currentRoute.value = name;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notify();
    _updateRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notify();
    if (previousRoute != null) {
      _updateRoute(previousRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notify();
    if (previousRoute != null) {
      _updateRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _notify();
    if (newRoute != null) {
      _updateRoute(newRoute);
    }
  }
}

class _BackButtonIcon extends StatefulWidget {
  final VoidCallback onTap;

  const _BackButtonIcon({required this.onTap});

  @override
  State<_BackButtonIcon> createState() => _BackButtonIconState();
}

class _BackButtonIconState extends State<_BackButtonIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonSize = size.width >= 600 ? 52.0 : 36.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          height: buttonSize,
          width: buttonSize,
          child: Image.asset(
            'assets/images/back.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _MusicToggleButton extends StatefulWidget {
  final bool isOn;
  final VoidCallback onTap;

  const _MusicToggleButton({required this.isOn, required this.onTap});

  @override
  State<_MusicToggleButton> createState() => _MusicToggleButtonState();
}

class _MusicToggleButtonState extends State<_MusicToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isOn) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _MusicToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isOn && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonSize = size.width >= 600 ? 52.0 : 36.0;
    final glowColor = const Color(0xFFFFF3A6).withOpacity(0.8);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isOn ? _scale.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Container(
                height: buttonSize,
                width: buttonSize,
                decoration: BoxDecoration(
                  boxShadow: [
                    if (widget.isOn)
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                  ],
                ),
                child: Image.asset(
                  widget.isOn
                      ? 'assets/images/on.png'
                      : 'assets/images/off.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResetButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ResetButton({required this.onTap});

  @override
  State<_ResetButton> createState() => _ResetButtonState();
}

class _ResetButtonState extends State<_ResetButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonSize = size.width >= 600 ? 56.0 : 40.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          height: buttonSize,
          width: buttonSize,
          child: Image.asset(
            'assets/images/reset.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// class MusicHandler extends WidgetsBindingObserver {
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       Music.music.pause();
//     } else if (state == AppLifecycleState.resumed) {
//       Music.music.resume();
//     }
//   }
// }
