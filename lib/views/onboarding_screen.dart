import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

// --- First-run flag (device-local, like the theme preference) ---
final ValueNotifier<bool> onboardingSeenNotifier = ValueNotifier<bool>(true);
const String _kOnboardKey = 'seen_onboarding';

Future<void> loadOnboardingSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    onboardingSeenNotifier.value = prefs.getBool(_kOnboardKey) ?? false;
  } catch (_) {
    onboardingSeenNotifier.value = true; // don't block startup on error
  }
}

Future<void> _complete() async {
  onboardingSeenNotifier.value = true;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardKey, true);
  } catch (_) {/* ignore */}
}

class _Page {
  final IconData icon;
  final String title;
  final String body;
  const _Page(this.icon, this.title, this.body);
}

const List<_Page> _pages = [
  _Page(Icons.favorite_rounded, 'Welcome to SiSi 💞',
      'Your cozy little place for love notes, plans and the dates that matter.'),
  _Page(Icons.checklist_rounded, 'Notes & reminders',
      'Jot down date ideas and personal plans, tick them off, and get reminded before your special dates.'),
  _Page(Icons.forum_rounded, 'A space for two',
      'Link with your partner using a couple code and share one Common feed you can both write in.'),
];

/// Simple 3-page intro shown on the very first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _complete();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool last = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _complete,
                child: Text('Skip',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.softPink(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon,
                              size: 56, color: AppColors.crimson),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.heading(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.crimson
                        : AppColors.crimson.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 24, 36, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  child: Text(last ? 'Get started 💕' : 'Next',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
