import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/common_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'views/home_view.dart';
import 'views/special_dates_view.dart';

/// Global navigator so notification taps can navigate without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the saved theme (guarded internally) before the first frame.
  await loadThemeMode();

  // Render the UI immediately. All native setup runs afterwards and is fully
  // guarded, so a slow/failed native call can never block startup — otherwise
  // the app would sit forever on the launch/splash screen (seen on iOS).
  runApp(const LoveNotesApp());

  _initFirebase();
  _initNotifications();
}

/// Initialise Firebase for the shared Common feed. Failure is non-fatal: the
/// Common screen simply shows setup instructions and the rest of the app
/// (notes, special dates) keeps working entirely offline.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    CommonService.isReady = true;
  } catch (e) {
    CommonService.isReady = false;
    debugPrint('Firebase not configured — Common feed disabled: $e');
  }
}

/// Initialise notifications without blocking app startup.
Future<void> _initNotifications() async {
  try {
    await NotificationService.instance.init();

    // Tapping any reminder opens the Special Dates screen.
    NotificationService.instance.onReminderTap = _openSpecialDates;

    // If the app was cold-started by tapping a reminder, jump straight to it.
    if (await NotificationService.instance.launchedFromNotification()) {
      _openSpecialDates();
    }

    // Re-arm saved reminders (rolls yearly dates forward, survives reboots).
    await NotificationService.instance.rescheduleAll();
  } catch (e) {
    debugPrint('Notification initialisation failed: $e');
  }
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
