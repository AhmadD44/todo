import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/push_service.dart';
import '../theme/app_theme.dart';

/// Account management: name, password, email verification, logout, delete.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final name = user?.displayName ?? 'You';
    final email = user?.email ?? '';
    final verified = AuthService.isEmailVerified;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.crimson),
        centerTitle: true,
        title: Text(
          'Account',
          style: TextStyle(
            color: AppColors.heading(context),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.softPink(context),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.crimson,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.heading(context))),
                const SizedBox(height: 2),
                Text(email,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                if (verified)
                  _badge('Email verified', Icons.verified_rounded, Colors.green)
                else
                  _badge('Email not verified', Icons.error_outline_rounded,
                      Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 28),

          if (!verified) ...[
            _tile(
              icon: Icons.mark_email_read_rounded,
              label: 'Verify email',
              subtitle: 'Resend the verification link',
              onTap: _verifyEmail,
            ),
          ],
          _tile(
            icon: Icons.person_rounded,
            label: 'Edit name',
            subtitle: name,
            onTap: _editName,
          ),
          _tile(
            icon: Icons.lock_rounded,
            label: 'Change password',
            onTap: _changePassword,
          ),
          _tile(
            icon: Icons.logout_rounded,
            label: 'Log out',
            onTap: _logout,
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.delete_forever_rounded,
            label: 'Delete account',
            subtitle: 'Permanently removes your account and data',
            danger: true,
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? Colors.red.shade400 : AppColors.crimson;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context), width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: color),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: danger ? color : AppColors.bodyText(context))),
        subtitle: subtitle == null
            ? null
            : Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      ),
    );
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

  /// Sign out, then pop back to the root so the AuthGate's login screen shows
  /// (otherwise this pushed screen would stay on top of it).
  Future<void> _logout() async {
    final uid = AuthService.uid;
    if (uid != null) await PushService.removeToken(uid);
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _verifyEmail() async {
    try {
      await AuthService.sendEmailVerification();
      _toast('Verification email sent 💌 — check your inbox.');
    } catch (e) {
      _toast(AuthService.friendlyError(e));
    }
  }

  Future<void> _editName() async {
    final ctrl =
        TextEditingController(text: AuthService.currentUser?.displayName ?? '');
    final ok = await _formDialog(
      title: 'Edit name',
      icon: Icons.person_rounded,
      fields: [
        _DialogField(controller: ctrl, hint: 'Your name', icon: Icons.person),
      ],
      confirmLabel: 'Save',
    );
    if (ok != true) return;
    if (ctrl.text.trim().isEmpty) return;
    try {
      await AuthService.updateDisplayName(ctrl.text.trim());
      if (mounted) setState(() {});
      _toast('Name updated 💕');
    } catch (e) {
      _toast(AuthService.friendlyError(e));
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final ok = await _formDialog(
      title: 'Change password',
      icon: Icons.lock_rounded,
      fields: [
        _DialogField(
            controller: current,
            hint: 'Current password',
            icon: Icons.lock_outline,
            obscure: true),
        _DialogField(
            controller: next,
            hint: 'New password (6+ chars)',
            icon: Icons.lock_reset_rounded,
            obscure: true),
      ],
      confirmLabel: 'Update',
    );
    if (ok != true) return;
    try {
      await AuthService.updatePassword(
        currentPassword: current.text,
        newPassword: next.text,
      );
      _toast('Password updated 🔒');
    } catch (e) {
      _toast(AuthService.friendlyError(e));
    }
  }

  Future<void> _deleteAccount() async {
    final pass = TextEditingController();
    final ok = await _formDialog(
      title: 'Delete account',
      icon: Icons.delete_forever_rounded,
      danger: true,
      message:
          'This permanently deletes your account, notes and special dates. '
          'This cannot be undone. Enter your password to confirm.',
      fields: [
        _DialogField(
            controller: pass,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscure: true),
      ],
      confirmLabel: 'Delete forever',
    );
    if (ok != true) return;
    try {
      await AuthService.deleteAccount(pass.text);
      // Pop back to the root; the AuthGate then shows the login screen.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _toast(AuthService.friendlyError(e));
    }
  }

  /// Generic themed dialog with one or more fields; returns true on confirm.
  Future<bool?> _formDialog({
    required String title,
    required IconData icon,
    required List<_DialogField> fields,
    required String confirmLabel,
    String? message,
    bool danger = false,
  }) {
    final accent = danger ? Colors.red.shade400 : AppColors.crimson;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.dialogBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.heading(context))),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message != null) ...[
              Text(message,
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
            ],
            for (int i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              TextField(
                controller: fields[i].controller,
                obscureText: fields[i].obscure,
                style: TextStyle(color: AppColors.bodyText(context)),
                decoration: InputDecoration(
                  hintText: fields[i].hint,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(fields[i].icon, color: accent, size: 20),
                  filled: true,
                  fillColor: AppColors.pickerField(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.pink.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel',
                style: TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 1,
            ),
            child: Text(confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _DialogField {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;

  _DialogField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });
}
