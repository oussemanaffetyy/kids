import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:project_v1/services/stats_store.dart';

class TracingGame extends StatefulWidget {
  const TracingGame({super.key});

  @override
  State<TracingGame> createState() => _TracingGameState();
}

class _TracingGameState extends State<TracingGame>
    with TickerProviderStateMixin {
  static const bool _traceDebug = true;
  final Random _random = Random();
  final List<Offset> _trail = [];
  final List<Offset> _pathPoints = [];
  final List<_PathSample> _pathSamples = [];
  final List<List<Path>> _levelPaths = [];
  Size _canvasSize = Size.zero;
  int _level = 1;
  bool _tracking = false;
  bool _showStars = false;
  bool _lockInput = false;
  bool _isClosedPath = false;
  Offset _start = Offset.zero;
  Offset _end = Offset.zero;
  double _lastProgress = 0;
  double _endProgress = 1;
  List<int> _shapeOrder = [];
  int _shapeIndex = 0;

  int _errors = 0;
  int _correct = 0;
  DateTime _startedAt = DateTime.now();
  bool _saved = false;
  bool _hasPlayed = false;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _guideCtrl;
  late final Animation<double> _guideAnim;

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

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _guideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _guideAnim = CurvedAnimation(parent: _guideCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    if (_hasPlayed && !_saved) {
      _saveStatsIfNeeded();
    }
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    _guideCtrl.dispose();
    super.dispose();
  }

  bool _isTabletLayout(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  double _threshold(bool isTablet) => isTablet ? 36 : 30;

  double _closedTargetProgress(bool isTablet) => isTablet ? 0.88 : 0.78;

  void _log(String msg) {
    if (!_traceDebug) return;
    final line = '[Tracing] $msg';
    // ignore: avoid_print
    print(line);
    debugPrint(line);
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
        gameKey: 'tracing',
        durationSeconds: duration,
        errors: _errors,
        correct: _correct,
      ),
    );
  }

  void _buildPaths(Size size) {
    if (_canvasSize == size && _levelPaths.isNotEmpty) return;
    _canvasSize = size;
    _levelPaths.clear();

    final w = size.width;
    final h = size.height;
    final pad = min(w, h) * 0.12;

    // Level 1: lines
    final l1 = <Path>[
      Path()
        ..moveTo(pad, h * 0.5)
        ..lineTo(w - pad, h * 0.5),
      Path()
        ..moveTo(w * 0.5, pad)
        ..lineTo(w * 0.5, h - pad),
      Path()
        ..moveTo(pad, h * 0.72)
        ..lineTo(w - pad, h * 0.72),
    ];

    // Level 2: curves
    final l2 = <Path>[
      Path()
        ..moveTo(pad, h * 0.35)
        ..cubicTo(w * 0.35, h * 0.05, w * 0.65, h * 0.65, w - pad, h * 0.35),
      Path()
        ..moveTo(pad, h * 0.6)
        ..quadraticBezierTo(w * 0.5, h * 0.1, w - pad, h * 0.6),
      Path()
        ..moveTo(pad, h * 0.4)
        ..quadraticBezierTo(w * 0.5, h * 0.9, w - pad, h * 0.4),
    ];

    // Level 3: shapes
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, h * 0.25, w - pad * 2, h * 0.5),
      Radius.circular(min(w, h) * 0.12),
    );
    final l3 = <Path>[
      Path()..addRRect(r),
      Path()..addOval(Rect.fromLTWH(pad, h * 0.2, w - pad * 2, h * 0.6)),
      Path()
        ..moveTo(pad, h * 0.3)
        ..lineTo(w - pad, h * 0.3)
        ..lineTo(w - pad, h * 0.7)
        ..lineTo(pad, h * 0.7)
        ..close(),
    ];

    // Level 4: number-like strokes
    final l4 = <Path>[
      Path()
        ..moveTo(w * 0.5, h * 0.2)
        ..lineTo(w * 0.5, h * 0.8),
      Path()
        ..moveTo(w * 0.35, h * 0.25)
        ..lineTo(w * 0.65, h * 0.25)
        ..lineTo(w * 0.35, h * 0.8),
      Path()
        ..moveTo(w * 0.35, h * 0.25)
        ..lineTo(w * 0.65, h * 0.25)
        ..lineTo(w * 0.65, h * 0.55)
        ..lineTo(w * 0.35, h * 0.55)
        ..lineTo(w * 0.65, h * 0.8),
    ];

    _levelPaths.addAll([l1, l2, l3, l4]);
    _initShapeOrder();
    _updatePathPoints();
  }

  void _initShapeOrder() {
    final count = _levelPaths[_level - 1].length;
    _shapeOrder = List.generate(count, (i) => i)..shuffle(_random);
    _shapeIndex = 0;
  }

  Path _currentPath() {
    final list = _levelPaths[_level - 1];
    final idx = _shapeOrder.isEmpty ? 0 : _shapeOrder[_shapeIndex];
    return list[idx];
  }

  void _updatePathPoints() {
    _pathPoints.clear();
    _pathSamples.clear();
    final path = _currentPath();
    for (final metric in path.computeMetrics()) {
      final len = metric.length;
      const step = 8.0;
      for (double d = 0; d < len; d += step) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) {
          _pathPoints.add(tangent.position);
          _pathSamples.add(_PathSample(tangent.position, d / len));
        }
      }
      // Always include the exact path end sample so progress can reach 1.0.
      final endTangent = metric.getTangentForOffset(len);
      if (endTangent != null) {
        _pathPoints.add(endTangent.position);
        _pathSamples.add(_PathSample(endTangent.position, 1.0));
      }
    }
    if (_pathPoints.isNotEmpty) {
      final metric = _currentPath().computeMetrics().first;
      final len = metric.length;
      final startTangent = metric.getTangentForOffset(0);
      // For closed paths, use the opposite (longer) direction.
      _isClosedPath = metric.isClosed;
      final isTablet = _isTabletLayout(context);
      final closedTarget = _closedTargetProgress(isTablet);
      final endOffset = metric.isClosed ? (len * closedTarget) : len;
      _endProgress = endOffset / len;
      final endTangent = metric.getTangentForOffset(endOffset.clamp(0, len));
      if (startTangent != null) {
        _start = startTangent.position;
      }
      if (endTangent != null) {
        _end = endTangent.position;
      }
      _log(
        'Level=$_level shape=${_shapeIndex + 1}/${_levelPaths[_level - 1].length} '
        'closed=$_isClosedPath len=${len.toStringAsFixed(1)} '
        'start=$_start end=$_end endProgress=${_endProgress.toStringAsFixed(3)}',
      );
    }
  }

  double _minDistance(Offset p) {
    var minD = double.infinity;
    for (final q in _pathPoints) {
      final d = (p - q).distance;
      if (d < minD) minD = d;
    }
    return minD;
  }

  double _nearestProgress(Offset p) {
    var minD = double.infinity;
    var best = 0.0;
    for (final s in _pathSamples) {
      final d = (p - s.pos).distance;
      if (d < minD) {
        minD = d;
        best = s.t;
      }
    }
    return best;
  }

  void _resetTrace() {
    _log(
      'RESET level=$_level shape=${_shapeIndex + 1} '
      'trail=${_trail.length} lastProgress=${_lastProgress.toStringAsFixed(3)}',
    );
    _trail.clear();
    _tracking = false;
    setState(() {});
  }

  Future<void> _success() async {
    _log(
      'SUCCESS level=$_level shape=${_shapeIndex + 1} '
      'progress=${_lastProgress.toStringAsFixed(3)}',
    );
    _lockInput = true;
    _correct += 1;
    setState(() => _showStars = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _showStars = false);

    if (_shapeIndex < _levelPaths[_level - 1].length - 1) {
      _shapeIndex += 1;
      _trail.clear();
      _tracking = false;
      _lockInput = false;
      _updatePathPoints();
      _guideCtrl.repeat();
      setState(() {});
      return;
    }

    if (_level < _levelPaths.length) {
      _level += 1;
      _initShapeOrder();
      _trail.clear();
      _tracking = false;
      _lockInput = false;
      _updatePathPoints();
      _guideCtrl.repeat();
      setState(() {});
      return;
    }
    await _saveStatsIfNeeded();
    await _showWinDialog();
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
    _level = 1;
    _initShapeOrder();
    _trail.clear();
    _tracking = false;
    _lockInput = false;
    _updatePathPoints();
    _guideCtrl.repeat();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = _isTabletLayout(context);
    const backgroundPath = 'assets/gamenumbers/bg.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(backgroundPath, fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 46),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: List.generate(
                    _level - 1,
                    (index) => Image.asset(
                      'assets/images/level.png',
                      width: isTablet ? 42 : 32,
                      height: isTablet ? 42 : 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: isTablet ? size.width * 0.7 : size.width * 0.9,
                      height: isTablet ? size.height * 0.6 : size.height * 0.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          _buildPaths(Size(c.maxWidth, c.maxHeight));
                          return AnimatedBuilder(
                            animation: Listenable.merge(
                                [_shakeAnim, _pulseAnim, _guideAnim]),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_shakeAnim.value, 0),
                                child: child,
                              );
                            },
                            child: GestureDetector(
                              onPanDown: (d) {
                                final local = d.localPosition;
                                _log(
                                  'DOWN level=$_level shape=${_shapeIndex + 1} '
                                  'local=$local start=$_start '
                                  'distStart=${(local - _start).distance.toStringAsFixed(1)} '
                                  'lock=$_lockInput',
                                );
                                if (_lockInput) {
                                  _log('DOWN blocked: locked');
                                  return;
                                }
                                if ((local - _start).distance >
                                    _threshold(isTablet) * 1.3) {
                                  _log(
                                    'DOWN rejected: too far from start '
                                    'dist=${(local - _start).distance.toStringAsFixed(1)} '
                                    'allow=${(_threshold(isTablet) * 1.3).toStringAsFixed(1)}',
                                  );
                                  return;
                                }
                                _hasPlayed = true;
                                _tracking = true;
                                _guideCtrl.stop();
                                _lastProgress = 0;
                                _trail
                                  ..clear()
                                  ..add(local);
                                _log('DOWN accepted: tracking started');
                                setState(() {});
                              },
                              onPanStart: (d) {
                                if (_lockInput) return;
                                final local = d.localPosition;
                                _log(
                                  'START local=$local start=$_start '
                                  'distStart=${(local - _start).distance.toStringAsFixed(1)}',
                                );
                                if ((local - _start).distance >
                                    _threshold(isTablet)) {
                                  _log(
                                    'START rejected: too far '
                                    'dist=${(local - _start).distance.toStringAsFixed(1)} '
                                    'allow=${_threshold(isTablet).toStringAsFixed(1)}',
                                  );
                                  return;
                                }
                                _hasPlayed = true;
                                _tracking = true;
                                _trail
                                  ..clear()
                                  ..add(local);
                                setState(() {});
                              },
                              onPanUpdate: (d) {
                                if (!_tracking || _lockInput) return;
                                final local = d.localPosition;
                                final minDistance = _minDistance(local);
                                final allowedDistance = _threshold(isTablet);
                                if (minDistance > allowedDistance) {
                                  _log(
                                    'UPDATE reject: out of path '
                                    'minDist=${minDistance.toStringAsFixed(1)} '
                                    'allow=${allowedDistance.toStringAsFixed(1)} '
                                    'local=$local',
                                  );
                                  _errors += 1;
                                  _shakeCtrl.forward(from: 0);
                                  _resetTrace();
                                  _guideCtrl.repeat();
                                  return;
                                }
                                _trail.add(local);
                                final progress = _nearestProgress(local);
                                final backtrackTolerance = 0.01;
                                if (!_isClosedPath &&
                                    progress + backtrackTolerance <
                                        _lastProgress) {
                                  _log(
                                    'UPDATE reject: backtrack '
                                    'progress=${progress.toStringAsFixed(3)} '
                                    'last=${_lastProgress.toStringAsFixed(3)} '
                                    'tol=$backtrackTolerance local=$local',
                                  );
                                  _errors += 1;
                                  _shakeCtrl.forward(from: 0);
                                  _resetTrace();
                                  _guideCtrl.repeat();
                                  return;
                                }
                                _lastProgress = max(_lastProgress, progress);
                                final distToEnd = (local - _end).distance;
                                final nearEndFactor = _isClosedPath
                                    ? (isTablet ? 2.2 : 3.0)
                                    : 1.5;
                                final nearEnd = distToEnd <
                                    _threshold(isTablet) * nearEndFactor;
                                final progressSlack = _isClosedPath
                                    ? (isTablet ? 0.05 : 0.14)
                                    : 0.02;
                                final reachedEnd = _lastProgress >=
                                    (_endProgress - progressSlack);
                                _log(
                                  'UPDATE level=$_level shape=${_shapeIndex + 1} '
                                  'progress=${_lastProgress.toStringAsFixed(3)} '
                                  'target=${(_endProgress - progressSlack).toStringAsFixed(3)} '
                                  'distEnd=${distToEnd.toStringAsFixed(1)} '
                                  'nearEnd=$nearEnd reached=$reachedEnd '
                                  'closed=$_isClosedPath',
                                );
                                if (reachedEnd && nearEnd) {
                                  _tracking = false;
                                  _success();
                                }
                                setState(() {});
                              },
                              onPanEnd: (_) {
                                if (!_tracking) return;
                                _resetTrace();
                                _guideCtrl.repeat();
                              },
                              child: CustomPaint(
                                painter: _TracePainter(
                                  path: _currentPath(),
                                  trail: _trail,
                                  start: _start,
                                  end: _end,
                                  pulse: _pulseAnim.value,
                                  guideProgress: _guideAnim.value,
                                  showGuide: false,
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
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
          if (_showStars)
            Center(
              child: Lottie.asset(
                'assets/json/stars.json',
                width: isTablet ? 180 : 140,
                height: isTablet ? 180 : 140,
                repeat: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final Path path;
  final List<Offset> trail;
  final Offset start;
  final Offset end;
  final double pulse;
  final double guideProgress;
  final bool showGuide;

  _TracePainter({
    required this.path,
    required this.trail,
    required this.start,
    required this.end,
    required this.pulse,
    required this.guideProgress,
    required this.showGuide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = const Color(0xFF2E7DFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, pathPaint);

    if (showGuide) {
      final guidePaint = Paint()
        ..color = const Color(0xFF9ED0FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      for (final metric in path.computeMetrics()) {
        final len = metric.length;
        final guideLen = len * 0.7;
        final dash = 24.0;
        final gap = 14.0;
        final startOffset = guideProgress * guideLen;
        for (double d = 0; d < guideLen; d += dash + gap) {
          final head = (startOffset + d) % guideLen;
          final segment = metric.extractPath(
            head,
            min(head + dash, guideLen),
          );
          canvas.drawPath(segment, guidePaint);
        }
      }
    }

    final trailPaint = Paint()
      ..color = const Color(0xFF00B3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < trail.length; i++) {
      canvas.drawLine(trail[i - 1], trail[i], trailPaint);
    }

    final startPaint = Paint()..color = const Color(0xFF3DDC84);
    final glowPaint = Paint()
      ..color = const Color(0xFFB8F3C6).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final startRadius = 14 + (pulse * 5);
    canvas.drawCircle(start, startRadius + 7, glowPaint);
    canvas.drawCircle(start, startRadius, startPaint);

    final endPaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(end, 16, endPaint);
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) {
    return oldDelegate.trail != trail ||
        oldDelegate.path != path ||
        oldDelegate.start != start ||
        oldDelegate.end != end;
  }
}

class _PathSample {
  final Offset pos;
  final double t;

  const _PathSample(this.pos, this.t);
}
