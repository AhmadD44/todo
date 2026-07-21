import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores who you are and which couple feed you're linked to.
///
/// Pairing is deliberately simple: one partner generates a code, the other
/// types the same code in. Both devices then read/write the same feed — no
/// accounts, passwords or login screens.
class CoupleService {
  CoupleService._();

  static const String _codeKey = 'couple_code';
  static const String _nameKey = 'couple_display_name';

  /// The saved couple code and display name (both null when not paired yet).
  static Future<({String? code, String? name})> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (
        code: prefs.getString(_codeKey),
        name: prefs.getString(_nameKey),
      );
    } catch (_) {
      return (code: null, name: null);
    }
  }

  static Future<void> save({required String code, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codeKey, code);
    await prefs.setString(_nameKey, name);
  }

  static Future<void> unpair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_codeKey);
    await prefs.remove(_nameKey);
  }

  /// Builds a friendly, easy-to-share code such as `SISI-4X7Q`.
  static String generateCode() {
    // No confusable characters (0/O, 1/I) so the code is easy to read aloud.
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final suffix =
        List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    return 'SISI-$suffix';
  }

  /// Normalises user input so `sisi-4x7q` and `SISI-4X7Q` pair together.
  static String normalise(String raw) => raw.trim().toUpperCase();
}
