import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/common_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'views/auth_gate.dart';
import 'views/onboarding_screen.dart';
import 'views/special_dates_view.dart';

/// Global navigator so notification taps can navigate without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the saved theme + onboarding flag (guarded) before the first frame.
  await loadThemeMode();
  await loadOnboardingSeen();

  // Firebase must be ready before the AuthGate can decide login vs. home.
  // initializeApp is fast and works offline, so awaiting it is safe.
  await _initFirebase();

  runApp(const LoveNotesApp());

  // Notification setup runs afterwards, fully guarded, so it can never block
  // startup (which would leave the app stuck on the splash screen on iOS).
  _initNotifications();
}

/// Initialise Firebase (auth + Firestore). Failure is non-fatal: the app falls
/// back to a signed-out local experience and Common shows its setup screen.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    CommonService.isReady = true;

    // Route uncaught Flutter + async errors to Crashlytics (mobile only).
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    CommonService.isReady = false;
    debugPrint('Firebase not configured: $e');
  }
}

/// Initialise notifications without blocking app startup. Reminders themselves
/// are (re)scheduled once the signed-in user's special dates load.
Future<void> _initNotifications() async {
  try {
    await NotificationService.instance.init();

    // Tapping any reminder opens the Special Dates screen.
    NotificationService.instance.onReminderTap = _openSpecialDates;

    // If the app was cold-started by tapping a reminder, jump straight to it.
    if (await NotificationService.instance.launchedFromNotification()) {
      _openSpecialDates();
    }
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
          home: const _Root(),
        );
      },
    );
  }
}

/// Shows onboarding on first launch, otherwise the auth gate.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: onboardingSeenNotifier,
      builder: (context, seen, _) =>
          seen ? const AuthGate() : const OnboardingScreen(),
    );
  }
}
