import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Shown when a signed-in user hasn't verified their email yet. They can't
/// reach the app until [AuthService.isEmailVerified] is true.
class VerifyEmailScreen extends StatefulWidget {
  /// Called once the email is confirmed verified, so the gate can move on.
  final VoidCallback onVerified;
  const VerifyEmailScreen({super.key, required this.onVerified});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _poll;
  bool _checking = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    // Auto-check every few seconds so the screen advances on its own once the
    // user taps the link in their inbox.
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.snackPlum,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(message),
        ),
      );
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    if (!silent) setState(() => _checking = true);
    try {
      await AuthService.reloadUser();
      if (AuthService.isEmailVerified) {
        _poll?.cancel();
        widget.onVerified();
        return;
      }
      if (!silent) _toast('Not verified yet — check your inbox 💌');
    } catch (_) {
      if (!silent) _toast('Could not check right now. Try again.');
    } finally {
      if (mounted && !silent) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await AuthService.sendEmailVerification();
      _toast('Verification email sent 💌');
    } catch (e) {
      _toast(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? 'your email';
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.softPink(context),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_rounded,
                    size: 52, color: AppColors.crimson),
              ),
              const SizedBox(height: 28),
              Text(
                'Verify your email 💌',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.heading(context),
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.4),
                  children: [
                    const TextSpan(text: 'We sent a verification link to\n'),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                          color: AppColors.crimson, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                        text:
                            '.\nTap it, then come back — this will continue automatically.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '(If you don\'t see it, check your spam folder.)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checking ? null : () => _check(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  child: _checking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('I\'ve verified — continue',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _resending ? null : _resend,
                child: Text(
                  _resending ? 'Sending…' : 'Resend email',
                  style: const TextStyle(
                      color: AppColors.crimson, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => AuthService.signOut(),
                child: Text('Use a different account',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
