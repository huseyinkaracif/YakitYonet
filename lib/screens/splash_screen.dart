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
    await _fuelController.forward();
    // Animasyon tam doldu, kısa bir bekleme sonra geçiş yap
    await Future.delayed(const Duration(milliseconds: 400));
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
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(140, 140),
                              painter: FuelGaugePainter(
                                progress: _fuelAnimation.value,
                              ),
                            ),
                            // App icon in the center
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
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

    // Arka plan dairesi (boş tank)
    final bgPaint = Paint()
      ..color = AppTheme.surfaceCard
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      // Sıvı animasyonu için clipping (maske)
      final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.save();
      canvas.clipPath(clipPath);

      // Sıvı dalga çizgisi (fluid path)
      final waterPath = Path();
      
      // Sıvı seviyesi (aşağıdan yukarıya doğru y ekseni azalır)
      final waterLevel = (center.dy + radius) - (2 * radius * progress);

      waterPath.moveTo(center.dx - radius, center.dy + radius);
      waterPath.lineTo(center.dx - radius, waterLevel);

      // Sinüs dalgası (hareket hissi için phase eklendi)
      final phase = progress * pi * 8; 
      final amplitude = progress > 0.03 && progress < 0.97 ? 8.0 : 0.0; 
      
      for (double i = 0; i <= 2 * radius; i += 2) {
        final x = center.dx - radius + i;
        final y = waterLevel + sin((i / radius) * pi + phase) * amplitude;
        waterPath.lineTo(x, y);
      }

      waterPath.lineTo(center.dx + radius, center.dy + radius);
      waterPath.close();

      // Suyun rengi
      final waterPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppTheme.accentBlue, AppTheme.accentCyan, AppTheme.accentGreen],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawPath(waterPath, waterPaint);
      canvas.restore();
    }

    // Dış halka parlaması
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.accentBlue, AppTheme.accentCyan],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);

    // İkon için iç kısımdan suyun geçmesini engellemek amaçlı arka plan rengiyle dolgu
    final cutoutPaint = Paint()
      ..color = AppTheme.primaryDark
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.65, cutoutPaint);
  }

  @override
  bool shouldRepaint(covariant FuelGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
