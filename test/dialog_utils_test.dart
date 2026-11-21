import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_mate/core/utils/dialog_utils.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('DialogUtils Confirmation Tests', () {
    testWidgets('showLogoutConfirmation shows dialog and returns true on confirm', (tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmed = await DialogUtils.showLogoutConfirmation(context);
              },
              child: const Text('Trigger Logout'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Logout'), findsNWidgets(2)); // Title & button
      expect(find.text('Are you sure you want to log out of ExaMore?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Logout button
      final logoutButton = find.widgetWithText(ElevatedButton, 'Logout');
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });

    testWidgets('showLogoutConfirmation returns false on cancel', (tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmed = await DialogUtils.showLogoutConfirmation(context);
              },
              child: const Text('Trigger Logout'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Logout'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
    });

    testWidgets('showExitConfirmation shows dialog and returns true on confirm', (tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmed = await DialogUtils.showExitConfirmation(context);
              },
              child: const Text('Trigger Exit'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Exit'));
      await tester.pumpAndSettle();

      expect(find.text('Exit ExaMore'), findsOneWidget);
      expect(find.text('Are you sure you want to exit the application?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      final exitButton = find.widgetWithText(ElevatedButton, 'Exit');
      await tester.tap(exitButton);
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });

    testWidgets('showExitConfirmation returns false on cancel', (tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmed = await DialogUtils.showExitConfirmation(context);
              },
              child: const Text('Trigger Exit'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Exit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
    });
  });
}
