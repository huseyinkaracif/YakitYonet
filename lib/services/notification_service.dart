import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../database/database_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_notify');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  /// Android 13+ POST_NOTIFICATIONS iznini ister; verilmişse true döner.
  Future<bool> ensurePermission() async {
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// İzin yoksa veya tarih geçmişteyse false döner, hata fırlatmaz.
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return false;
    if (!await ensurePermission()) return false;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'yakit_yonet_channel_id',
            'Hatırlatıcılar',
            channelDescription: 'Sigorta ve Bakım Hatırlatıcıları',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notify',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Sigorta/vergi bitiş hatırlatıcılarını DB'den yeniden kurar.
  /// Bitişten 7 gün önce 09:00; o an geçmişse bitiş günü 09:00.
  Future<void> rescheduleAllFromDb() async {
    if (!await ensurePermission()) return;

    final now = DateTime.now();
    final vehicles = await DatabaseHelper.instance.getAllVehicles();

    for (final vehicle in vehicles) {
      if (vehicle.id == null) continue;
      final records =
          await DatabaseHelper.instance.getInsuranceTaxRecords(vehicle.id!);

      for (final record in records) {
        final expiry = record.expiryDate;
        if (record.id == null || expiry == null || !expiry.isAfter(now)) {
          continue;
        }

        var reminderDate = DateTime(expiry.year, expiry.month, expiry.day, 9)
            .subtract(const Duration(days: 7));
        if (reminderDate.isBefore(now)) {
          reminderDate = DateTime(expiry.year, expiry.month, expiry.day, 9);
        }

        await scheduleNotification(
          id: record.id!,
          title: '${record.type} Hatırlatıcısı',
          body:
              '${record.provider ?? record.type} kaydınızın yenilenme tarihi yaklaşıyor.',
          scheduledDate: reminderDate,
        );
      }
    }
  }
}
