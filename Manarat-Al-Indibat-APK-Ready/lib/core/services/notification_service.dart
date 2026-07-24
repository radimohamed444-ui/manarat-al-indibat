import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:permission_handler/permission_handler.dart";
import "package:timezone/timezone.dart" as tz;
import "package:timezone/data/latest_all.dart" as tz_data;
import "../../domain/services/notification_dispatcher.dart";

/// Real, on-device implementation of [NotificationDispatcher] —
/// `flutter_local_notifications` + `timezone` for scheduling and
/// `permission_handler` for the OS permission prompt. No server, no
/// push service (FCM/APNs) involved at all — every notification is
/// generated and fired locally, per the "Local AI / Offline" spec
/// requirement.
///
/// Call [init] once in `main()` before anything tries to notify.
class NotificationService implements NotificationDispatcher {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel behaviorChannel = AndroidNotificationChannel(
    "behavior_ai",
    "المدرب السلوكي الذكي",
    description: "تنبيهات وتحليلات المدرب السلوكي الذكي في منارة الانضباط",
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // Falls back to the device's local zone; apps that need an exact
    // IANA name can wire `flutter_timezone` here later.
    tz.setLocalLocation(tz.local);

    const androidInit = AndroidInitializationSettings("@mipmap/ic_launcher");
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // requested explicitly via requestPermission()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings);

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(behaviorChannel);

    _initialized = true;
  }

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          behaviorChannel.id,
          behaviorChannel.name,
          channelDescription: behaviorChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: "@mipmap/ic_launcher",
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  @override
  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    // Android 13+ (API 33) needs POST_NOTIFICATIONS at runtime; iOS
    // needs the Darwin alert/badge/sound prompt. permission_handler
    // covers the Android side; the iOS prompt goes through the plugin
    // itself since permission_handler's iOS notification status can
    // be unreliable pre-authorization.
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;
    if (androidImpl != null) {
      granted = await androidImpl.requestNotificationsPermission() ?? await hasPermission();
    }
    if (iosImpl != null) {
      granted = await iosImpl.requestPermissions(alert: true, badge: true, sound: true) ?? granted;
    }
    return granted;
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? channelId,
  }) async {
    await init();
    await _plugin.show(id, title, body, _details);
  }

  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? channelId,
    bool rollToNextDayIfPast = true,
  }) async {
    await init();
    var target = tz.TZDateTime.from(when, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (target.isBefore(now) && rollToNextDayIfPast) {
      target = target.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      target,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }
}
