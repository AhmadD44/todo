import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/common_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'home_view.dart';
import 'verify_email_screen.dart';

/// Decides what to show based on auth state:
///   • signed out            → login / signup
///   • signed in, unverified → verify-email screen (can't reach the app)
///   • signed in, verified   → home
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    // If Firebase failed to initialise there's no auth — fall back to the app
    // so the rest keeps working (Common shows its "needs Firebase" screen).
    if (!CommonService.isReady) return const HomeScreen();

    return StreamBuilder<User?>(
      stream: AuthService.authState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loading();
        }
        final user = snapshot.data;
        if (user == null) return const AuthScreen();
        if (!user.emailVerified) {
          // Rebuild once verified so the same stream user (now verified) passes.
          return VerifyEmailScreen(onVerified: () => setState(() {}));
        }
        return const HomeScreen();
      },
    );
  }

  Widget _loading() => Scaffold(
        backgroundColor: AppColors.scaffold(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.crimson),
        ),
      );
}
