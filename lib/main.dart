import 'package:flutter/material.dart';

import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'views/home_view.dart';
import 'views/special_dates_view.dart';

/// Global navigator so notification taps can navigate without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadThemeMode();
  await NotificationService.instance.init();

  // Tapping any reminder opens the Special Dates screen.
  NotificationService.instance.onReminderTap = _openSpecialDates;

  // Re-arm saved reminders (rolls yearly dates forward, survives reboots).
  await NotificationService.instance.rescheduleAll();

  runApp(const LoveNotesApp());

  // If the app was cold-started by tapping a reminder, jump straight to it.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (await NotificationService.instance.launchedFromNotification()) {
      _openSpecialDates();
    }
  });
}

void _openSpecialDates() {
  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => const SpecialDatesScreen()),
  );
}

/// Root application with romantic light & dark themes.
class LoveNotesApp extends StatelessWidget {
  const LoveNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'sisi notes',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: mode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
