import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../models/special_date.dart';

/// Wraps flutter_local_notifications: init, permissions, and scheduling the
/// three reminders (1 day before, 6 hours before, and at the moment) per date.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'special_dates_channel';
  static const String _channelName = 'Special Date Reminders';
  static const String _channelDesc = 'Reminders for your important dates 💖';
  static const String _icon = '@drawable/ic_stat_heart';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Invoked when the user taps one of our reminders (set by the app so the
  /// service stays decoupled from the UI layer).
  void Function()? onReminderTap;

  Future<void> init() async {
    if (_initialized) return;

    // Load the timezone database and point tz.local at the device's zone so
    // scheduled times fire at the wall-clock moment the user picked.
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // If the platform can't report a zone we fall back to the default (UTC).
    }

    const androidInit = AndroidInitializationSettings('ic_stat_heart');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) => onReminderTap?.call(),
    );

    // Pre-create the Android channel so reminders have the right importance.
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// True if the app was launched by tapping a notification (cold start).
  Future<bool> launchedFromNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }

  /// Ask for the runtime notification + exact-alarm permissions (Android 13+/12+).
  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          icon: _icon,
        ),
      );

  /// Schedule the three reminders for [d] (skipping any that are already past).
  Future<void> schedule(SpecialDate d) async {
    await cancel(d);

    final target = tz.TZDateTime.from(d.nextOccurrence(), tz.local);
    final now = tz.TZDateTime.now(tz.local);

    final reminders = <(int, tz.TZDateTime, String, String)>[
      (
        d.notifId,
        target.subtract(const Duration(days: 1)),
        '${d.emoji} Tomorrow: ${d.title}',
        'Just 1 day left until ${d.title}! 💕',
      ),
      (
        d.notifId + 1,
        target.subtract(const Duration(hours: 6)),
        '${d.emoji} In 6 hours: ${d.title}',
        '${d.title} is coming up in 6 hours! 🥰',
      ),
      (
        d.notifId + 2,
        target,
        '${d.emoji} Today: ${d.title}',
        'The big moment is here — ${d.title}! 💖',
      ),
    ];

    for (final (id, fireAt, title, body) in reminders) {
      if (fireAt.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: fireAt,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  Future<void> cancel(SpecialDate d) async {
    await _plugin.cancel(id: d.notifId);
    await _plugin.cancel(id: d.notifId + 1);
    await _plugin.cancel(id: d.notifId + 2);
  }

  /// Re-arm every saved reminder. Called at startup so yearly dates roll
  /// forward to their next occurrence and nothing is lost after a reboot.
  Future<void> rescheduleAll() async {
    final dates = await SpecialDate.loadAll();
    for (final d in dates) {
      await schedule(d);
    }
  }
}
