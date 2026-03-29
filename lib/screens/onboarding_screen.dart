import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _backupPreference = 'off';

  static const List<OnboardingPage> _pages = [
    OnboardingPage(
      imagePath: 'assets/images/onboarding_welcome.png',
      title: 'YakıtYönet\'e\nHoş Geldiniz',
      description:
          'Araçlarınızın yakıt tüketimini, bakımlarını ve masraflarını kolayca takip edin.',
      accentColor: AppTheme.accent,
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding_vehicles.png',
      title: 'Araçlarınızı\nEkleyin',
      description:
          'Birden fazla araç ekleyerek her birinin masraflarını ayrı ayrı takip edin.',
      accentColor: AppTheme.maintColor,
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding_stats.png',
      title: 'Detaylı\nİstatistikler',
      description:
          'TL/KM, L/100KM verileri, bakım maliyetleri ve sigorta giderlerini analiz edin.',
      accentColor: AppTheme.successColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('backup_preference', _backupPreference);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with skip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  // Brand mark
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_gas_station_rounded,
                        size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'YakıtYönet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Atla',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length + 1,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _buildInfoPage(_pages[index]);
                  } else {
                    return _buildBackupPage();
                  }
                },
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length + 1,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == index ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _currentPage == index
                              ? AppTheme.accent
                              : Theme.of(context).dividerTheme.color ?? AppTheme.borderSubtle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      child: Text(
                        _currentPage < _pages.length
                            ? 'Devam'
                            : 'Başlayalım!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildInfoPage(OnboardingPage page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                page.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    color: page.accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.image_rounded,
                    size: 56,
                    color: page.accentColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            page.title,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                'assets/images/onboarding_backup.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.cloud_upload_rounded,
                    size: 56,
                    color: AppTheme.accent.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Otomatik\nYedekleme',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: onSurface,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Verilerinizi Google Drive\'a otomatik olarak yedekleyin. Daha sonra ayarlardan değiştirebilirsiniz.',
            style: TextStyle(
              fontSize: 15,
              color: onSurface.withValues(alpha: 0.6),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          _buildBackupOption('off', 'Kapalı',
              Icons.cloud_off_rounded, 'Otomatik yedekleme yapılmaz'),
          _buildBackupOption('weekly', 'Haftalık',
              Icons.date_range_rounded, 'Her hafta otomatik yedeklenir'),
          _buildBackupOption('monthly', 'Aylık',
              Icons.calendar_month_rounded, 'Her ay otomatik yedeklenir'),
        ],
      ),
    );
  }

  Widget _buildBackupOption(
      String value, String label, IconData icon, String desc) {
    final isSelected = _backupPreference == value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _backupPreference = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accent.withValues(alpha: 0.1)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accent
                  : Theme.of(context).dividerTheme.color ?? AppTheme.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: isSelected
                        ? AppTheme.accent
                        : Theme.of(context).iconTheme.color,
                    size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.accent : onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String imagePath;
  final String title;
  final String description;
  final Color accentColor;

  const OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}
