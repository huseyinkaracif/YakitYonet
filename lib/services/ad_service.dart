import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdService {
  static final AdService instance = AdService._();
  AdService._();

  String get appId => dotenv.get('ADMOB_APP_ID_ANDROID', fallback: '');
  String get bannerId => dotenv.get('ADMOB_BANNER_ID_ANDROID', fallback: '');

  Future<void> init() async {
    // This will be used when google_mobile_ads package is added
    if (appId.isEmpty) return;
    print('AdMob initialized with ID: $appId');
  }
}
