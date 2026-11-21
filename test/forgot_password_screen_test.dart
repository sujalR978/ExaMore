import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_mate/features/auth/screens/forgot_password_screen.dart';
import 'package:prep_mate/features/auth/widgets/custom_button.dart';
import 'package:prep_mate/features/auth/widgets/input_field.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Forgot Password Screen Tests', () {
    testWidgets('Renders Request Reset step with header and input field', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const ForgotPasswordPage()));
      await tester.pump();

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Email or Phone Number'), findsOneWidget);
      expect(find.widgetWithText(Button, 'SEND VERIFICATION CODE'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('Validates required identifier when submitted empty', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const ForgotPasswordPage()));
      await tester.pump();

      final sendBtn = find.widgetWithText(Button, 'SEND VERIFICATION CODE');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.text('Email or phone number is required'), findsOneWidget);
    });

    testWidgets('Validates 10-digit phone number when digits entered', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const ForgotPasswordPage()));
      await tester.pump();

      final idField = find.widgetWithText(Inputfield, 'student@university.edu or 10-digit phone');
      await tester.enterText(idField, '12345');
      await tester.pump();

      final sendBtn = find.widgetWithText(Button, 'SEND VERIFICATION CODE');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.text('Phone number must be exactly 10 digits'), findsOneWidget);
    });

    testWidgets('Completes full Reset flow: Request -> OTP -> New Password -> Success', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const ForgotPasswordPage()));
      await tester.pump();

      // Step 1: Submit valid email
      final idField = find.widgetWithText(Inputfield, 'student@university.edu or 10-digit phone');
      await tester.enterText(idField, 'student@example.com');
      await tester.pump();

      final sendBtn = find.widgetWithText(Button, 'SEND VERIFICATION CODE');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Step 2: Verify OTP step rendered
      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.text('6-Digit OTP Code'), findsOneWidget);
      expect(find.widgetWithText(Button, 'VERIFY CODE'), findsOneWidget);

      // Try entering invalid OTP
      final otpField = find.widgetWithText(Inputfield, 'Enter 6-digit numeric OTP');
      await tester.enterText(otpField, '999999');
      await tester.pump();

      final verifyBtn = find.widgetWithText(Button, 'VERIFY CODE');
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Incorrect verification code. Please check and try again.'), findsOneWidget);

      // Enter valid fallback test OTP '123456'
      await tester.enterText(otpField, '123456');
      await tester.pump();
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // Step 3: Verify Set New Password step rendered
      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.widgetWithText(Button, 'RESET PASSWORD'), findsOneWidget);

      // Enter new password adhering to strong criteria
      final newPassField = find.widgetWithText(Inputfield, 'Enter strong new password');
      final confirmPassField = find.widgetWithText(Inputfield, 'Re-enter new password');

      await tester.enterText(newPassField, 'NewStrongP@ss1');
      await tester.enterText(confirmPassField, 'NewStrongP@ss1');
      await tester.pump();

      final resetBtn = find.widgetWithText(Button, 'RESET PASSWORD');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Step 4: Verify Success screen
      expect(find.text('Password Reset Complete!'), findsOneWidget);
      expect(find.widgetWithText(Button, 'BACK TO LOGIN'), findsOneWidget);
    });
  });
}
