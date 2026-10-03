import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';
import 'package:prep_mate/features/User/Navigator/mainNavigator.dart';
import 'package:prep_mate/features/User/screen/reviewAnswersScreen.dart';
import 'package:prep_mate/features/User/widget/CircularProgressWithText.dart';


class ExamResultScreen extends StatefulWidget {
  final ExamModel? exam;
  final StudentSubmissionModel? submission;

  const ExamResultScreen({
    super.key,
    this.exam,
    this.submission,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  final ExamService _examService = ExamService();

  late ExamModel _exam;
  late StudentSubmissionModel _submission;

  @override
  void initState() {
    super.initState();
    _exam = widget.exam ??
        ExamModel(
          id: 'sample_id',
          examCode: 'EXM-2026-001',
          title: 'Assessment Evaluation',
          category: 'General',
          durationMinutes: 60,
          totalMarks: 50,
          passingScorePercentage: 60,
        );

    _submission = widget.submission ??
        StudentSubmissionModel(
          id: 'sample_sub_id',
          studentName: 'Student User',
          studentId: 'STU-1042',
          examTitle: _exam.title,
          scorePercentage: 84.0,
          marksObtained: 42.0,
          totalMarks: _exam.totalMarks > 0 ? _exam.totalMarks : 50.0,
          correctAnswers: 42,
          incorrectAnswers: 5,
          unattemptedAnswers: 3,
          isPassed: true,
          submittedAt: DateTime.now(),
        );
  }

  void _handleReviewAnswers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewAnswersScreen(
          exam: _exam,
          submission: _submission,
        ),
      ),
    );
  }

  void _handleSave() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigator()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    final isPassed = _submission.isPassed;
    final scoreRatio =
        (_submission.scorePercentage / 100).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school,
                          color: isDarkMode
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF1E1B4B),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    'Examora',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Exam Result',
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _exam.title,
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Score Overview Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // PASS / FAIL Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? (isDarkMode
                              ? const Color(0xFF064E3B)
                              : const Color(0xFFD1FAE5))
                          : (isDarkMode
                              ? const Color(0xFF451A03)
                              : const Color(0xFFFEF2F2)),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isPassed ? 'PASS' : 'NEEDS IMPROVEMENT',
                      style: TextStyle(
                        color: isPassed
                            ? (isDarkMode
                                ? const Color(0xFF34D399)
                                : const Color(0xFF065F46))
                            : const Color(0xFFDC2626),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Score numbers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _submission.marksObtained.toStringAsFixed(
                          _submission.marksObtained.truncateToDouble() ==
                                  _submission.marksObtained
                              ? 0
                              : 1,
                        ),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/${_submission.totalMarks.toInt()}',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Score Points',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Visual Circular Progress
                  CustomCircularProgress(
                    progress: scoreRatio,
                    text: '${_submission.scorePercentage.toInt()}%',
                    width: 120,
                    height: 120,
                    circleSize: 160,
                    strokeWidth: 14,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Class Rank Banner (Live calculation from cohort submissions)
            StreamBuilder<List<StudentSubmissionModel>>(
              stream: _examService.getExamSubmissionsStream(_exam.id),
              builder: (context, snapshot) {
                final allSubmissions = snapshot.data ?? [];
                int rank = 1;
                final total = allSubmissions.length;

                if (total > 0) {
                  final idx = allSubmissions.indexWhere(
                    (s) => s.id == _submission.id,
                  );
                  if (idx >= 0) rank = idx + 1;
                }

                String suffix = 'th';
                if (rank == 1) suffix = 'st';
                if (rank == 2) suffix = 'nd';
                if (rank == 3) suffix = 'rd';

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1E1B4B)
                        : const Color(0xFF0F0E17),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.military_tech,
                                color: Color(0xFFFBBF24),
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Class Rank',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$rank',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                suffix,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            total > 1
                                ? 'Ranked $rank out of $total submissions'
                                : 'First evaluation recorded for this exam',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.white.withOpacity(0.1),
                        size: 70,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Stats Row: Correct, Incorrect, Skipped
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.check_circle,
                    const Color(0xFF10B981),
                    '${_submission.correctAnswers}',
                    'CORRECT',
                    containerColor,
                    textColor,
                    borderColor,
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.cancel,
                    const Color(0xFFEF4444),
                    '${_submission.incorrectAnswers}',
                    'INCORRECT',
                    containerColor,
                    textColor,
                    borderColor,
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.remove_circle,
                    const Color(0xFF64748B),
                    '${_submission.unattemptedAnswers}',
                    'SKIPPED',
                    containerColor,
                    textColor,
                    borderColor,
                    isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subject Breakdown Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject Breakdown',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSubjectBar(
                    _exam.category,
                    '${_submission.scorePercentage.toInt()}%',
                    scoreRatio,
                    textColor,
                    subtitleColor,
                    isDarkMode,
                  ),
                  const SizedBox(height: 16),
                  _buildSubjectBar(
                    'Accuracy',
                    '${_submission.correctAnswers + _submission.incorrectAnswers > 0 ? ((_submission.correctAnswers / (_submission.correctAnswers + _submission.incorrectAnswers)) * 100).toInt() : 0}%',
                    _submission.correctAnswers + _submission.incorrectAnswers > 0
                        ? (_submission.correctAnswers /
                            (_submission.correctAnswers +
                                _submission.incorrectAnswers))
                        : 0.0,
                    textColor,
                    subtitleColor,
                    isDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Review Answers CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleReviewAnswers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: const Color(0xFF1E1B4B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Review Answers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: const Color(0xFF1E1B4B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Save & Exit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    Color iconColor,
    String value,
    String label,
    Color containerColor,
    Color textColor,
    Color borderColor,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBar(
    String subject,
    String percentageText,
    double value,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              percentageText,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: isDarkMode
                ? const Color(0xFF1E293B)
                : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF1E1B4B),
            ),
          ),
        ),
      ],
    );
  }
}