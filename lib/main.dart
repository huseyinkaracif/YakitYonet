import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/vehicle_list_screen.dart';
import 'screens/add_vehicle_screen.dart';
import 'screens/vehicle_detail_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/backup_screen.dart';
import 'services/google_drive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or could not be loaded: $e");
  }

  await GoogleDriveService.instance.init();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(YakitYonetApp(onboardingComplete: onboardingComplete));
}

class YakitYonetApp extends StatelessWidget {
  final bool onboardingComplete;

  const YakitYonetApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: dotenv.get('APP_NAME', fallback: 'Yakıt Yönetimi'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return _buildRoute(const SplashScreen(), settings);
          case '/onboarding':
            return _buildRoute(const OnboardingScreen(), settings);
          case '/home':
            // Check if onboarding was already completed
            if (!onboardingComplete) {
              // Check again in case it was just completed
              return _buildRoute(
                FutureBuilder<bool>(
                  future: _checkOnboarding(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.data == true) {
                      return const VehicleListScreen();
                    }
                    return const OnboardingScreen();
                  },
                ),
                settings,
              );
            }
            return _buildRoute(const VehicleListScreen(), settings);
          case '/add-vehicle':
            return _buildRoute(const AddVehicleScreen(), settings);
          case '/vehicle-detail':
            final vehicleId = settings.arguments as int;
            return _buildRoute(
                VehicleDetailScreen(vehicleId: vehicleId), settings);
          case '/statistics':
            return _buildRoute(const StatisticsScreen(), settings);
          case '/backup':
            return _buildRoute(const BackupScreen(), settings);
          default:
            return _buildRoute(const VehicleListScreen(), settings);
        }
      },
    );
  }

  static Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
