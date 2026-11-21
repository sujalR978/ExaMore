import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_mate/features/user/screens/show_exam_screen.dart';
import 'package:prep_mate/features/user/widgets/show_exams_widget.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('ExamCardWidget Compact Card Tests', () {
    testWidgets('Renders compact exam card with subject, status, title, metadata and action button', (tester) async {
      bool buttonPressed = false;
      bool bookmarkToggled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: ExamCardWidget(
              badgeText: 'Mathematics',
              title: 'Calculus Mid-Term Exam',
              time: '45 mins',
              mcqs: '30 MCQs',
              marks: '50 pts',
              statusText: 'Available Now',
              isUpcoming: false,
              isBookmarked: false,
              buttonText: 'Start Exam',
              onButtonPressed: () => buttonPressed = true,
              onBookmarkToggle: () => bookmarkToggled = true,
            ),
          ),
        ),
      );

      // Verify badges and title
      expect(find.text('MATHEMATICS'), findsOneWidget);
      expect(find.text('Available Now'), findsOneWidget);
      expect(find.text('Calculus Mid-Term Exam'), findsOneWidget);

      // Verify metadata
      expect(find.text('45 mins'), findsOneWidget);
      expect(find.text('30 MCQs'), findsOneWidget);
      expect(find.text('50 pts'), findsOneWidget);

      // Verify action button
      expect(find.text('Start Exam'), findsOneWidget);

      // Tap button and bookmark
      await tester.tap(find.text('Start Exam'));
      expect(buttonPressed, isTrue);

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      expect(bookmarkToggled, isTrue);
    });

    testWidgets('Renders upcoming badge and View Details button for upcoming exam', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: ExamCardWidget(
              badgeText: 'Physics',
              title: 'Quantum Mechanics Final',
              time: '60 mins',
              mcqs: '40 MCQs',
              marks: '100 pts',
              statusText: 'Opens Nov 25, 10:00 AM',
              isUpcoming: true,
              isBookmarked: true,
              buttonText: 'View Details',
              onButtonPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('PHYSICS'), findsOneWidget);
      expect(find.text('Opens Nov 25, 10:00 AM'), findsOneWidget);
      expect(find.text('Quantum Mechanics Final'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });
  });

  group('Showexam Screen Tests', () {
    testWidgets('Renders screen header, search bar, and no subject filter tabs', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const Showexam()));
      await tester.pump();

      // Check header title and description
      expect(find.text('Explore Exams'), findsOneWidget);
      expect(
        find.text('Upcoming and pending assessments for your classes.'),
        findsOneWidget,
      );

      // Check search input field and hint
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search upcoming exams, subjects...'), findsOneWidget);

      // Ensure subject filter chips are completely removed
      expect(find.text('All Subjects'), findsNothing);
    });
  });
}
