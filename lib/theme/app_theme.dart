import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central palette + light/dark themes for the app.
///
/// Brand accent colours (crimson / rose) stay identical in both modes so the
/// romantic identity is preserved; only surfaces and text adapt to brightness.
class AppColors {
  AppColors._();

  // --- Fixed brand accents (same in light & dark) ---
  static const Color crimson = Color(0xFFC2185B);
  static const Color deepRose = Color(0xFFAD1457);
  static const Color rose = Color(0xFFEC407A);
  static const Color snackPlum = Color(0xFF4A148C);
  static const Color heartRed = Colors.redAccent;

  static bool isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  // --- Brightness-aware semantic colours ---
  static Color scaffold(BuildContext c) =>
      isDark(c) ? const Color(0xFF1A1114) : const Color(0xFFFFF8F9);

  static Color card(BuildContext c) =>
      isDark(c) ? const Color(0xFF261A20) : Colors.white;

  static Color doneCard(BuildContext c) =>
      isDark(c) ? const Color(0xFF1F161B) : const Color(0xFFF5ECEF);

  static Color heading(BuildContext c) =>
      isDark(c) ? const Color(0xFFF8BBD0) : const Color(0xFF880E4F);

  static Color bodyText(BuildContext c) =>
      isDark(c) ? const Color(0xFFECEFF1) : const Color(0xFF2C3E50);

  static Color softPink(BuildContext c) =>
      isDark(c) ? const Color(0xFF3A2530) : const Color(0xFFFCE4EC);

  static Color cardBorder(BuildContext c) =>
      isDark(c) ? const Color(0xFF3A2530) : const Color(0xFFFCE4EC);

  static Color dialogBg(BuildContext c) =>
      isDark(c) ? const Color(0xFF241820) : const Color(0xFFFFF5F6);

  static Color pickerField(BuildContext c) =>
      isDark(c) ? const Color(0xFF2E2029) : Colors.white;

  static Color leadingDates(BuildContext c) =>
      isDark(c) ? const Color(0xFF3A2530) : const Color(0xFFFFF1F3);

  static Color leadingPersonal(BuildContext c) =>
      isDark(c) ? const Color(0xFF2A2740) : const Color(0xFFE8EAF6);

  static Color muted(BuildContext c) =>
      isDark(c) ? Colors.grey.shade400 : Colors.grey.shade500;
}

/// Builds the [ThemeData] for the given [brightness].
ThemeData buildAppTheme(Brightness brightness) {
  final bool dark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    primaryColor: AppColors.deepRose,
    scaffoldBackgroundColor:
        dark ? const Color(0xFF1A1114) : const Color(0xFFFFF8F9),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.crimson,
      brightness: brightness,
      primary: AppColors.deepRose,
      secondary: AppColors.rose,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

// ---------------------------------------------------------------------------
//  App-wide theme mode state (persisted), toggled from the home AppBar.
// ---------------------------------------------------------------------------

final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

const String _kThemePrefKey = 'theme_mode';

/// Load the saved theme preference at startup.
Future<void> loadThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    themeNotifier.value =
        prefs.getString(_kThemePrefKey) == 'dark' ? ThemeMode.dark : ThemeMode.light;
  } catch (_) {
    themeNotifier.value = ThemeMode.light;
  }
}

/// Flip between light and dark and persist the choice.
Future<void> toggleThemeMode() async {
  final bool wasDark = themeNotifier.value == ThemeMode.dark;
  themeNotifier.value = wasDark ? ThemeMode.light : ThemeMode.dark;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemePrefKey, wasDark ? 'light' : 'dark');
  } catch (_) {/* ignore persistence errors */}
}
