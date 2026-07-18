// Basic smoke test for the sisi notes app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todo_app/main.dart';

void main() {
  setUp(() {
    // Provide an empty backing store so the async task load resolves cleanly.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots and shows the home title', (WidgetTester tester) async {
    await tester.pumpWidget(const LoveNotesApp());
    await tester.pumpAndSettle();

    expect(find.text('SiSi - NOTES'), findsOneWidget);
    // Both the theme toggle and Special Dates action should be present.
    expect(find.byIcon(Icons.celebration_rounded), findsOneWidget);
  });
}
