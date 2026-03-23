import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fuelController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fuelAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fuelController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fuelAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fuelController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _fuelController.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _fuelController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              AppTheme.primaryDark,
              Color(0xFF0A1628),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge(
                    [_scaleAnimation, _fadeAnimation, _fuelAnimation]),
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: CustomPaint(
                          painter: FuelGaugePainter(
                            progress: _fuelAnimation.value,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnimation,
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.accentGradient.createShader(bounds),
                  child: const Text(
                    'YakıtYönet',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Yakıt & Araç Yönetimi',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
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

class FuelGaugePainter extends CustomPainter {
  final double progress;

  FuelGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circle
    final bgPaint = Paint()
      ..color = AppTheme.surfaceCard
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.accentBlue, AppTheme.accentCyan, AppTheme.accentGreen],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5 * progress,
      false,
      progressPaint,
    );

    // Center fuel pump icon area
    final iconPaint = Paint()
      ..color = AppTheme.accentBlue.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, iconPaint);

    // Draw fuel pump symbol
    final pumpPaint = Paint()
      ..color = AppTheme.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Pump body
    final pumpRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - 6, center.dy),
        width: 28,
        height: 34,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(pumpRect, pumpPaint);

    // Pump handle
    final handlePath = Path()
      ..moveTo(center.dx + 8, center.dy - 17)
      ..lineTo(center.dx + 20, center.dy - 17)
      ..lineTo(center.dx + 20, center.dy - 4)
      ..lineTo(center.dx + 14, center.dy + 4);
    canvas.drawPath(handlePath, pumpPaint);

    // Nozzle dot
    canvas.drawCircle(
      Offset(center.dx + 14, center.dy + 6),
      2.5,
      Paint()..color = AppTheme.accentCyan,
    );
  }

  @override
  bool shouldRepaint(covariant FuelGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
