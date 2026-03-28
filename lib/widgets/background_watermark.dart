import 'package:flutter/material.dart';

class BackgroundWatermark extends StatelessWidget {
  final Widget child;
  
  const BackgroundWatermark({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Watermark Arkaplanı
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: isDark ? 0.05 : 0.05, // Şeffaflık seviyesi (çok hafif)
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: MediaQuery.of(context).size.width * 1, // Ekranın %80'i kadar büyük
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        // Gerçek içerik
        child,
      ],
    );
  }
}
