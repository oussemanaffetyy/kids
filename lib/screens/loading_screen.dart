import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _autoClose();
  }

  Future<void> _autoClose() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final backgroundPath = isTablet
        ? 'assets/images/2048x2732.png'
        : 'assets/images/1080x2400.png';
    final lottieWidth = (size.width * 0.75).clamp(260.0, 650.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AbsorbPointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                backgroundPath,
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Lottie.asset(
                'assets/json/loading.json',
                width: lottieWidth,
                height: lottieWidth,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
