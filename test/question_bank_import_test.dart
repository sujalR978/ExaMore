import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/screens/question_import_review_screen.dart';
import 'package:prep_mate/features/admin/services/question_file_parser.dart';

void main() {
  group('QuestionFileParser & Template Tests', () {
    test('generateSampleCsvTemplate produces valid headers and non-empty rows', () {
      final template = QuestionFileParser.generateSampleCsvTemplate(
        examTitle: 'Physics Exam',
        totalMarks: 30,
      );

      expect(template.contains('TOTAL MARKS: 30 pts'), isTrue);
      expect(template.contains('Question,Marks,Option A(Correct),Option B,Option C,Option D'), isTrue);
      expect(template.contains('electric current'), isTrue);
      expect(template.contains('photosynthesis'), isTrue);
      expect(template.contains('Tokyo'), isTrue);
    });
  });

  group('QuestionImportReviewScreen Widget Tests', () {
    final sampleQuestions = [
      QuestionModel(
        id: 'q1',
        questionText: 'What is the capital of France?',
        marks: 1.0,
        options: [
          QuestionOption(id: 'A', text: 'Berlin'),
          QuestionOption(id: 'B', text: 'Madrid'),
          QuestionOption(id: 'C', text: 'Paris'),
          QuestionOption(id: 'D', text: 'Rome'),
        ],
        correctOptionId: 'C',
        type: 'Multiple Choice',
        category: 'Geography',
        difficulty: 'Easy',
      ),
      QuestionModel(
        id: 'q2',
        questionText: 'Which planet is the Red Planet?',
        marks: 2.0,
        options: [
          QuestionOption(id: 'A', text: 'Venus'),
          QuestionOption(id: 'B', text: 'Mars'),
          QuestionOption(id: 'C', text: 'Jupiter'),
          QuestionOption(id: 'D', text: 'Saturn'),
        ],
        correctOptionId: 'B',
        type: 'Multiple Choice',
        category: 'Science',
        difficulty: 'Easy',
      ),
    ];

    testWidgets('Renders parsed questions list with correct options highlighted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionImportReviewScreen(
            questions: sampleQuestions,
            examTitle: 'Midterm Physics',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header summary
      expect(find.text('Review Question Bank'), findsOneWidget);
      expect(find.text('2 Questions Ready'), findsOneWidget);
      expect(find.text('Total: 3 Marks • 2/2 Validated'), findsOneWidget);

      // Question items
      expect(find.text('What is the capital of France?'), findsOneWidget);
      expect(find.text('Which planet is the Red Planet?'), findsOneWidget);

      // Correct badges
      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('Mars'), findsOneWidget);
      expect(find.text('Correct'), findsNWidgets(2));

      // Import button
      expect(find.text('Import 2 Questions'), findsOneWidget);
    });

    testWidgets('Tapping an option updates the correct answer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionImportReviewScreen(
            questions: sampleQuestions,
            examTitle: 'Midterm Physics',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Option A ('Berlin') on Q1
      await tester.tap(find.text('Berlin'));
      await tester.pumpAndSettle();

      // Option A should now be correct for Q1
      expect(find.text('Correct'), findsNWidgets(2));
    });

    testWidgets('Removing a question updates total count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionImportReviewScreen(
            questions: sampleQuestions,
            examTitle: 'Midterm Physics',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first delete icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('1 Questions Ready'), findsOneWidget);
      expect(find.text('Import 1 Questions'), findsOneWidget);
    });

    test('ExamModel.fromMap deserializes questions with dynamic maps correctly', () {
      final rawFirestoreData = {
        'id': 'exam_123',
        'title': 'Test Exam',
        'questions': [
          {
            'id': 'q1',
            'questionText': 'Question text from bank',
            'marks': 2,
            'options': [
              {'id': 'A', 'text': 'Option A text'},
              {'id': 'B', 'text': 'Option B text'},
            ],
            'correctOptionId': 'A',
            'type': 'Multiple Choice',
            'createdAt': '2026-11-23T10:00:00.000',
          }
        ],
      };

      final exam = ExamModel.fromMap(rawFirestoreData, 'exam_123');
      expect(exam.questions.length, 1);
      expect(exam.questions.first.questionText, 'Question text from bank');
      expect(exam.questions.first.marks, 2.0);
      expect(exam.questions.first.options.length, 2);
      expect(exam.questions.first.correctOptionId, 'A');
    });
  });
}
