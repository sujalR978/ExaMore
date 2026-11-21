import 'package:flutter_test/flutter_test.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/utils/exam_scoring_calculator.dart';

void main() {
  group('ExamScoringCalculator & Negative Marking Tests', () {
    final sampleQuestions = [
      QuestionModel(
        id: 'q1',
        questionText: 'What is Flutter?',
        marks: 4.0,
        options: [
          QuestionOption(id: 'opt1', text: 'UI SDK'),
          QuestionOption(id: 'opt2', text: 'Database'),
        ],
        correctOptionId: 'opt1',
      ),
      QuestionModel(
        id: 'q2',
        questionText: 'What is Dart?',
        marks: 4.0,
        options: [
          QuestionOption(id: 'opt3', text: 'Programming language'),
          QuestionOption(id: 'opt4', text: 'Operating system'),
        ],
        correctOptionId: 'opt3',
      ),
      QuestionModel(
        id: 'q3',
        questionText: 'What is Firebase?',
        marks: 2.0,
        options: [
          QuestionOption(id: 'opt5', text: 'Backend platform'),
          QuestionOption(id: 'opt6', text: 'Compiler'),
        ],
        correctOptionId: 'opt5',
      ),
    ];

    test('Awards full marks and marks as passed when all answers are correct', () {
      final selectedAnswers = {
        'q1': 'opt1',
        'q2': 'opt3',
        'q3': 'opt5',
      };

      final result = ExamScoringCalculator.calculate(
        questions: sampleQuestions,
        selectedAnswers: selectedAnswers,
        totalMarks: 10.0,
        passingScorePercentage: 40.0,
        negativeMarking: 1.0,
      );

      expect(result.correctCount, 3);
      expect(result.incorrectCount, 0);
      expect(result.unattemptedCount, 0);
      expect(result.marksObtained, 10.0);
      expect(result.scorePercentage, 100.0);
      expect(result.isPassed, isTrue);
    });

    test('Deducts negative marking accurately for incorrect answers', () {
      // 1 correct (4 marks), 1 incorrect (-1 mark), 1 unattempted (0 marks)
      final selectedAnswers = {
        'q1': 'opt1', // Correct: +4
        'q2': 'opt4', // Wrong: -1
        'q3': '',     // Unattempted: 0
      };

      final result = ExamScoringCalculator.calculate(
        questions: sampleQuestions,
        selectedAnswers: selectedAnswers,
        totalMarks: 10.0,
        passingScorePercentage: 50.0,
        negativeMarking: 1.0,
      );

      expect(result.correctCount, 1);
      expect(result.incorrectCount, 1);
      expect(result.unattemptedCount, 1);
      expect(result.marksObtained, 3.0); // 4 - 1 = 3
      expect(result.scorePercentage, 30.0);
      expect(result.isPassed, isFalse); // 30% < 50%
    });

    test('Clamps total marks to 0.0 when negative deductions exceed marks obtained', () {
      // 0 correct, 3 incorrect (-3 marks with 1.0 negative marking)
      final selectedAnswers = {
        'q1': 'opt2',
        'q2': 'opt4',
        'q3': 'opt6',
      };

      final result = ExamScoringCalculator.calculate(
        questions: sampleQuestions,
        selectedAnswers: selectedAnswers,
        totalMarks: 10.0,
        passingScorePercentage: 40.0,
        negativeMarking: 2.0,
      );

      expect(result.correctCount, 0);
      expect(result.incorrectCount, 3);
      expect(result.unattemptedCount, 0);
      expect(result.marksObtained, 0.0); // Clamped, not -6.0
      expect(result.scorePercentage, 0.0);
      expect(result.isPassed, isFalse);
    });

    test('Zero penalty for completely unattempted exam', () {
      final selectedAnswers = <String, String>{};

      final result = ExamScoringCalculator.calculate(
        questions: sampleQuestions,
        selectedAnswers: selectedAnswers,
        totalMarks: 10.0,
        passingScorePercentage: 40.0,
        negativeMarking: 1.0,
      );

      expect(result.correctCount, 0);
      expect(result.incorrectCount, 0);
      expect(result.unattemptedCount, 3);
      expect(result.marksObtained, 0.0);
      expect(result.scorePercentage, 0.0);
      expect(result.isPassed, isFalse);
    });

    test('Passes threshold check when exactly at passingScorePercentage', () {
      // 1 correct (4 marks), 2 unattempted (0 marks). Total: 4 / 10 = 40%
      final selectedAnswers = {
        'q1': 'opt1',
      };

      final result = ExamScoringCalculator.calculate(
        questions: sampleQuestions,
        selectedAnswers: selectedAnswers,
        totalMarks: 10.0,
        passingScorePercentage: 40.0,
        negativeMarking: 1.0,
      );

      expect(result.marksObtained, 4.0);
      expect(result.scorePercentage, 40.0);
      expect(result.isPassed, isTrue);
    });

    test('Handles descriptive questions properly', () {
      final descriptiveQuestion = QuestionModel(
        id: 'q_desc',
        questionText: 'Explain state management in Flutter',
        marks: 5.0,
        options: const [],
        correctOptionId: '',
        type: 'Descriptive',
      );

      final result = ExamScoringCalculator.calculate(
        questions: [descriptiveQuestion],
        selectedAnswers: {'q_desc': 'State management controls how data flows.'},
        totalMarks: 5.0,
        passingScorePercentage: 50.0,
        negativeMarking: 1.0,
      );

      expect(result.correctCount, 1);
      expect(result.incorrectCount, 0);
      expect(result.marksObtained, 5.0);
      expect(result.isPassed, isTrue);
    });
  });
}
