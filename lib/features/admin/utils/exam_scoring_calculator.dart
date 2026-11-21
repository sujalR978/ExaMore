import 'package:prep_mate/features/admin/models/exam_model.dart';

class ExamScoringResult {
  final int correctCount;
  final int incorrectCount;
  final int unattemptedCount;
  final double marksObtained;
  final double totalMarks;
  final double scorePercentage;
  final bool isPassed;

  const ExamScoringResult({
    required this.correctCount,
    required this.incorrectCount,
    required this.unattemptedCount,
    required this.marksObtained,
    required this.totalMarks,
    required this.scorePercentage,
    required this.isPassed,
  });
}

class ExamScoringCalculator {
  ExamScoringCalculator._();

  static ExamScoringResult calculate({
    required List<QuestionModel> questions,
    required Map<String, dynamic> selectedAnswers,
    required double totalMarks,
    required double passingScorePercentage,
    required double negativeMarking,
  }) {
    int correctCount = 0;
    int incorrectCount = 0;
    int unattemptedCount = 0;
    double totalMarksObtained = 0.0;

    for (var question in questions) {
      final chosenOption = selectedAnswers[question.id]?.toString();
      if (chosenOption == null || chosenOption.trim().isEmpty) {
        unattemptedCount++;
      } else if (question.type == 'Descriptive' || question.options.isEmpty) {
        // Descriptive answer: award full marks if student entered an answer
        correctCount++;
        totalMarksObtained += question.marks;
      } else if (chosenOption == question.correctOptionId) {
        correctCount++;
        totalMarksObtained += question.marks;
      } else {
        incorrectCount++;
        totalMarksObtained -= negativeMarking;
      }
    }

    if (totalMarksObtained < 0) totalMarksObtained = 0.0;

    final double scorePercentage = totalMarks > 0
        ? (totalMarksObtained / totalMarks) * 100.0
        : 0.0;

    final bool isPassed = scorePercentage >= passingScorePercentage;

    return ExamScoringResult(
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      unattemptedCount: unattemptedCount,
      marksObtained: totalMarksObtained,
      totalMarks: totalMarks,
      scorePercentage: scorePercentage,
      isPassed: isPassed,
    );
  }
}
