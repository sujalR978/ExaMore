import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prep_mate/core/theme/theme_provider.dart';
import 'package:prep_mate/features/user/screens/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'email_notifications': true,
      'exam_reminders': false,
      'selected_language': 'English',
    });
  });

  Widget buildTestableSettings() {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: const MaterialApp(
        home: Settingscreen(),
      ),
    );
  }

  group('Settings Screen Tests', () {
    testWidgets('Renders theme, preferences, permissions, and legal sections',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableSettings());
      await tester.pumpAndSettle();

      // Check sections
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Email Notifications'), findsOneWidget);
      expect(find.text('Study Streak Reminders'), findsOneWidget);
      expect(find.text('App Language'), findsOneWidget);
      expect(find.text('App Permissions'), findsOneWidget);
      expect(find.text('Account & Legal'), findsOneWidget);
      expect(find.text('Clear App Cache'), findsOneWidget);
      expect(find.text('Delete Account & Data'), findsOneWidget);
      expect(find.text('ExaMore v1.0.0 (Build 1)'), findsOneWidget);
    });

    testWidgets('App Language dialog opens and selects a new language',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableSettings());
      await tester.pumpAndSettle();

      // Tap App Language
      await tester.tap(find.text('App Language'));
      await tester.pumpAndSettle();

      // Verify language options in dialog
      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.text('French'), findsOneWidget);

      // Select Spanish
      await tester.tap(find.text('Spanish'));
      await tester.pumpAndSettle();

      // Verify Spanish is now displayed
      expect(find.text('Spanish'), findsOneWidget);

      // Verify SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_language'), 'Spanish');
    });

    testWidgets('App Permissions dialog displays required device permissions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableSettings());
      await tester.pumpAndSettle();

      // Tap App Permissions
      await tester.tap(find.text('App Permissions'));
      await tester.pumpAndSettle();

      // Verify permissions modal
      expect(find.text('Internet Access'), findsOneWidget);
      expect(find.text('Storage / Photos'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Internet Access'), findsNothing);
    });

    testWidgets('Clear App Cache dialog clears cache and shows confirmation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableSettings());
      await tester.pumpAndSettle();

      // Scroll to Clear App Cache
      final clearCacheTile = find.text('Clear App Cache');
      await tester.ensureVisible(clearCacheTile);
      await tester.tap(clearCacheTile);
      await tester.pumpAndSettle();

      expect(find.text('Clear Cache?'), findsOneWidget);

      // Tap Clear
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Cache cleared successfully (0 KB remaining).'), findsOneWidget);
    });
  });
}
