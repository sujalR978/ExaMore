import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/auth/widgets/custom_button.dart';
import 'package:prep_mate/features/auth/widgets/input_field.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Login Screen Tests', () {
    testWidgets('Renders all login widgets and branding elements', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const Login()));
      await tester.pump();

      // Check header and titles
      expect(find.text('ExaMore Login'), findsOneWidget);
      expect(find.text('Email or Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Check CTAs
      expect(find.widgetWithText(Button, 'LOGIN'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('Validates required fields when submitted empty', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const Login()));
      await tester.pump();

      final loginBtn = find.widgetWithText(Button, 'LOGIN');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Email or phone number is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Validates 10-digit phone number when digits entered', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const Login()));
      await tester.pump();

      final idField = find.widgetWithText(Inputfield, 'Enter email or 10-digit phone number');
      await tester.enterText(idField, '98765');
      await tester.pump();

      final loginBtn = find.widgetWithText(Button, 'LOGIN');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Phone number must be exactly 10 digits'), findsOneWidget);
    });

    testWidgets('Validates email format when invalid email string entered', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const Login()));
      await tester.pump();

      final idField = find.widgetWithText(Inputfield, 'Enter email or 10-digit phone number');
      await tester.enterText(idField, 'invalid-email');
      await tester.pump();

      final loginBtn = find.widgetWithText(Button, 'LOGIN');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address or 10-digit phone number'), findsOneWidget);
    });

    testWidgets('Rejects spaces in email/phone input field', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const Login()));
      await tester.pump();

      final idField = find.widgetWithText(Inputfield, 'Enter email or 10-digit phone number');
      await tester.enterText(idField, ' student@test.com ');
      await tester.pump();

      final loginBtn = find.widgetWithText(Button, 'LOGIN');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Leading, trailing, or embedded spaces are not allowed'), findsOneWidget);
    });
  });
}
