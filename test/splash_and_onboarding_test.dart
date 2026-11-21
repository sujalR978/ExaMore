import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prep_mate/features/auth/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders first onboarding page with branding and Skip button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Verify Page 1 title & subtitle
      expect(find.text("Master Your Exams"), findsOneWidget);
      expect(find.text("Smart Practice & Mock Tests"), findsOneWidget);
      expect(find.text("Skip"), findsOneWidget);
      expect(find.text("NEXT"), findsOneWidget);
      // Previous button should not be visible on page 0
      expect(find.text("Back"), findsNothing);
    });

    testWidgets('Next button navigates through all 3 pages and reveals Get Started',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Page 1 -> tap NEXT
      await tester.tap(find.text("NEXT"));
      await tester.pumpAndSettle();

      // Verify Page 2
      expect(find.text("Actionable Insights"), findsOneWidget);
      expect(find.text("Back"), findsOneWidget);
      expect(find.text("NEXT"), findsOneWidget);

      // Page 2 -> tap NEXT
      await tester.tap(find.text("NEXT"));
      await tester.pumpAndSettle();

      // Verify Page 3
      expect(find.text("Classroom Cohorts"), findsOneWidget);
      expect(find.text("Back"), findsOneWidget);
      expect(find.text("GET STARTED"), findsOneWidget);
      // Skip should be hidden on page 3
      expect(find.text("Skip"), findsNothing);
    });

    testWidgets('Back button navigates to previous page',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Go to page 2
      await tester.tap(find.text("NEXT"));
      await tester.pumpAndSettle();
      expect(find.text("Actionable Insights"), findsOneWidget);

      // Tap Back
      await tester.tap(find.text("Back"));
      await tester.pumpAndSettle();

      // Returned to page 1
      expect(find.text("Master Your Exams"), findsOneWidget);
      expect(find.text("Back"), findsNothing);
    });

    testWidgets('Tapping Skip saves onboarding_completed in SharedPreferences',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      await tester.tap(find.text("Skip"));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), true);
    });
  });
}
