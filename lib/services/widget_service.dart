
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';

class WidgetService {
  static const String appGroupId = 'com.yakityonet.yakit_yonet';
  static const String androidWidgetName = 'FuelWidgetProvider';
  static const String androidSmallWidgetName = 'FuelWidgetSmallProvider';
  static const String _defaultVehicleKey = 'default_vehicle_id';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<int?> getDefaultVehicleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_defaultVehicleKey);
  }

  static Future<void> setDefaultVehicleId(int? vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    if (vehicleId == null) {
      await prefs.remove(_defaultVehicleKey);
    } else {
      await prefs.setInt(_defaultVehicleKey, vehicleId);
    }
  }

  static Future<void> updateWidgetData(
    Vehicle? vehicle, {
    double costPerKm = 0.0,
    double litersPer100 = 0.0,
  }) async {
    if (vehicle != null) {
      await HomeWidget.saveWidgetData<String>('vehicle_name', vehicle.name);
      await HomeWidget.saveWidgetData<String>(
          'vehicle_km', '${vehicle.currentKm.toStringAsFixed(0)} km');
      await HomeWidget.saveWidgetData<String>(
          'vehicle_image_path', vehicle.imagePath ?? '');
      await HomeWidget.saveWidgetData<String>('fuel_type', vehicle.fuelType);
      await HomeWidget.saveWidgetData<String>('cost_per_km',
          costPerKm > 0 ? '${costPerKm.toStringAsFixed(2)} ₺/km' : '—');
      await HomeWidget.saveWidgetData<String>('liters_per_100',
          litersPer100 > 0 ? '${litersPer100.toStringAsFixed(1)} L/100' : '—');
    } else {
      await HomeWidget.saveWidgetData<String>('vehicle_name', 'Araç Seçilmedi');
      await HomeWidget.saveWidgetData<String>('vehicle_km', '');
      await HomeWidget.saveWidgetData<String>('vehicle_image_path', '');
      await HomeWidget.saveWidgetData<String>('fuel_type', '');
      await HomeWidget.saveWidgetData<String>('cost_per_km', '—');
      await HomeWidget.saveWidgetData<String>('liters_per_100', '—');
    }

    await HomeWidget.updateWidget(
      name: androidWidgetName,
      androidName: androidWidgetName,
    );
    await HomeWidget.updateWidget(
      name: androidSmallWidgetName,
      androidName: androidSmallWidgetName,
    );
  }

  static Future<Uri?> getInitiallyLaunchedFromWidget() async {
    return await HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  /// Stream that fires when the widget is tapped while the app is already running.
  static Stream<Uri?> get widgetClickedStream => HomeWidget.widgetClicked;

  static bool isAddFuelUri(Uri? uri) =>
      uri != null && uri.scheme == 'yakityonet' && uri.host == 'widget';
}
