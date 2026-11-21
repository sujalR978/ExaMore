import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_mate/features/user/screens/exam_attempts_history_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('ExamAttemptsHistoryScreen Widget Tests', () {
    testWidgets('Renders screen header, search bar, and filter buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const ExamAttemptsHistoryScreen()));
      await tester.pump();

      // Check header title and description
      expect(find.text('Exam Attempts History'), findsOneWidget);
      expect(
        find.text('Track your scores, answers, and progress over time'),
        findsOneWidget,
      );

      // Check search input field and hint
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search exam, subject, or date...'), findsOneWidget);

      // Check time period filter button
      expect(find.text('All Time'), findsOneWidget);
    });

    testWidgets('Time filter dropdown displays all options when tapped', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const ExamAttemptsHistoryScreen()));
      await tester.pump();

      final filterButton = find.text('All Time');
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Verify dropdown options
      expect(find.text('Past 7 Days'), findsOneWidget);
      expect(find.text('Past 30 Days'), findsOneWidget);
      expect(find.text('This Year'), findsOneWidget);
    });
  });
}
