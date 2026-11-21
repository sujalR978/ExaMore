import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_mate/features/auth/screens/registration_screen.dart';
import 'package:prep_mate/features/auth/widgets/custom_button.dart';
import 'package:prep_mate/features/auth/widgets/input_field.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Registration Screen Tests', () {
    testWidgets('Renders all fields and ensures Instructor Code is removed for students', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const Registration()));
      await tester.pump();

      // Check header and titles
      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Admin / Instructor'), findsOneWidget);

      // Verify fields
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Verify Instructor Code field is COMPLETELY REMOVED from Student registration
      expect(find.text('Instructor Code (Optional)'), findsNothing);
      expect(find.text("Instructor's UID or Email"), findsNothing);
      expect(find.text("Instructor email or UID"), findsNothing);

      // Verify Terms and conditions checkbox
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.textContaining('Terms of Service', findRichText: true), findsOneWidget);
      expect(find.textContaining('Privacy Policy', findRichText: true), findsOneWidget);

      // Verify Register button
      expect(find.widgetWithText(Button, 'REGISTER'), findsOneWidget);
    });

    testWidgets('Validates required fields when submitted empty', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const Registration()));
      await tester.pump();

      // Tap Register button without filling form
      final registerButton = find.widgetWithText(Button, 'REGISTER');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Field validation error messages under textfields
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Enforces 10-digit phone number validation', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const Registration()));
      await tester.pump();

      // Find Phone Number field
      final phoneField = find.widgetWithText(Inputfield, 'Enter 10-digit phone number');
      expect(phoneField, findsOneWidget);

      // Enter 5 digits
      await tester.enterText(phoneField, '98765');
      await tester.pump();

      // Scroll and tap Register
      final registerButton = find.widgetWithText(Button, 'REGISTER');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Phone number must be exactly 10 digits'), findsOneWidget);
    });

    testWidgets('Enforces strong password policy (8+ chars, uppercase, lowercase, number, symbol)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const Registration()));
      await tester.pump();

      final passwordField = find.widgetWithText(Inputfield, 'Enter strong password');
      expect(passwordField, findsOneWidget);

      final registerButton = find.widgetWithText(Button, 'REGISTER');

      // 1. Too short (< 8 chars)
      await tester.enterText(passwordField, 'Abc1!');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 8 characters long'), findsOneWidget);

      // 2. Missing uppercase
      await tester.enterText(passwordField, 'abc12345!');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();
      expect(find.text('Password must contain an uppercase letter (A-Z)'), findsOneWidget);

      // 3. Missing lowercase
      await tester.enterText(passwordField, 'ABC12345!');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();
      expect(find.text('Password must contain a lowercase letter (a-z)'), findsOneWidget);

      // 4. Missing number
      await tester.enterText(passwordField, 'Abcdefgh!');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();
      expect(find.text('Password must contain a number (0-9)'), findsOneWidget);

      // 5. Missing special character
      await tester.enterText(passwordField, 'Abcdefg1');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();
      expect(find.text('Password must contain a special character (!@#\$&*)'), findsOneWidget);
    });

    testWidgets('Blocks submission if Terms & Conditions are not accepted', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const Registration()));
      await tester.pump();

      // Fill in valid details
      await tester.enterText(find.widgetWithText(Inputfield, 'Enter your full name'), 'John Doe');
      await tester.enterText(find.widgetWithText(Inputfield, 'Enter 10-digit phone number'), '9876543210');
      await tester.enterText(find.widgetWithText(Inputfield, 'Enter your email address'), 'john.doe@example.com');
      await tester.enterText(find.widgetWithText(Inputfield, 'Enter strong password'), 'StrongP@ss1');
      await tester.enterText(find.widgetWithText(Inputfield, 'Re-enter your password'), 'StrongP@ss1');
      await tester.pump();

      // Submit without accepting terms
      final registerButton = find.widgetWithText(Button, 'REGISTER');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Shows friendly toast / snackbar demanding terms agreement
      expect(find.text('Please agree to the Terms of Service & Privacy Policy to continue.'), findsOneWidget);

      // Check the checkbox
      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final Checkbox checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, isTrue);
    });
  });
}
