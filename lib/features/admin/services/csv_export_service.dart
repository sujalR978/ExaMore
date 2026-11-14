import 'package:prep_mate/features/admin/models/exam_model.dart';

class CsvExportService {
  /// Generates a standardized RFC 4180 compliant CSV string containing student marksheet
  static String generateExamSubmissionsCsv({
    required ExamModel exam,
    required List<StudentSubmissionModel> submissions,
  }) {
    final List<List<dynamic>> rows = [];

    // Metadata header rows
    rows.add(['Exam Title', exam.title]);
    rows.add(['Exam Code', exam.examCode]);
    rows.add(['Category', exam.category]);
    rows.add(['Total Marks', exam.totalMarks]);
    rows.add(['Passing %', '${exam.passingScorePercentage}%']);
    rows.add([]); // empty row

    // Table Columns Header
    rows.add([
      'Rank',
      'Student Name',
      'Student ID',
      'Score %',
      'Marks Obtained',
      'Total Marks',
      'Correct Answers',
      'Incorrect Answers',
      'Unattempted Answers',
      'Result Status',
      'Submission Timestamp',
    ]);

    // Sort descending by score
    final sorted = List<StudentSubmissionModel>.from(submissions)
      ..sort((a, b) => b.scorePercentage.compareTo(a.scorePercentage));

    for (int i = 0; i < sorted.length; i++) {
      final s = sorted[i];
      final isPassed =
          s.isPassed || s.scorePercentage >= exam.passingScorePercentage;

      rows.add([
        i + 1,
        s.studentName,
        s.studentId,
        '${s.scorePercentage.toStringAsFixed(1)}%',
        s.marksObtained.toStringAsFixed(1),
        s.totalMarks.toStringAsFixed(1),
        s.correctAnswers,
        s.incorrectAnswers,
        s.unattemptedAnswers,
        isPassed ? 'Passed' : 'Failed',
        s.submittedAt.toIso8601String(),
      ]);
    }

    return rows.map((row) {
      return row.map((cell) {
        final str = cell.toString().replaceAll('"', '""');
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          return '"$str"';
        }
        return str;
      }).join(',');
    }).join('\n');
  }
}
