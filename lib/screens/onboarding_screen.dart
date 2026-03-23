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

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.local_gas_station_rounded,
      title: 'YakıtYönet\'e Hoş Geldiniz!',
      description:
          'Araçlarınızın yakıt tüketimini, bakımlarını ve masraflarını kolayca takip edin.',
      color: AppTheme.accentBlue,
    ),
    OnboardingPage(
      icon: Icons.directions_car_rounded,
      title: 'Araçlarınızı Ekleyin',
      description:
          'Birden fazla araç ekleyerek her birinin masraflarını ayrı ayrı takip edin. Detaylı grafiklerle tüketim verilerinizi görselleştirin.',
      color: AppTheme.accentGreen,
    ),
    OnboardingPage(
      icon: Icons.bar_chart_rounded,
      title: 'Detaylı İstatistikler',
      description:
          'TL/KM, L/100KM tüketim verileri, bakım maliyetleri ve sigorta giderlerini analiz edin.',
      color: AppTheme.accentOrange,
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Atla',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              // Page view
              Expanded(
                child: _currentPage < _pages.length
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length + 1,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          if (index < _pages.length) {
                            return _buildInfoPage(_pages[index]);
                          } else {
                            return _buildBackupPage();
                          }
                        },
                      )
                    : _buildBackupPage(),
              ),
              // Dots and button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length + 1,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == index
                                ? AppTheme.accentBlue
                                : AppTheme.dividerColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Next / Start button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                        child: Text(
                          _currentPage < _pages.length
                              ? 'Devam'
                              : 'Başlayalım!',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.color.withOpacity(0.15),
              border: Border.all(color: page.color.withOpacity(0.3), width: 2),
            ),
            child: Icon(page.icon, size: 56, color: page.color),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentPurple.withOpacity(0.15),
              border: Border.all(
                  color: AppTheme.accentPurple.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.cloud_upload_rounded,
                size: 56, color: AppTheme.accentPurple),
          ),
          const SizedBox(height: 40),
          const Text(
            'Otomatik Yedekleme',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Verilerinizi Google Drive\'a otomatik olarak yedekleyin. Daha sonra ayarlardan değiştirebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildBackupOption('off', 'Kapalı', Icons.cloud_off_rounded),
          _buildBackupOption('weekly', 'Haftalık', Icons.date_range_rounded),
          _buildBackupOption('monthly', 'Aylık', Icons.calendar_month_rounded),
        ],
      ),
    );
  }

  Widget _buildBackupOption(String value, String label, IconData icon) {
    final isSelected = _backupPreference == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _backupPreference = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentPurple.withOpacity(0.15)
                : AppTheme.surfaceOverlay,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentPurple
                  : AppTheme.dividerColor.withOpacity(0.5),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isSelected
                      ? AppTheme.accentPurple
                      : AppTheme.textSecondary),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accentPurple, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
