// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/core/widgets/app_image_view.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/user/navigation/main_navigator.dart';
import 'package:prep_mate/features/user/widgets/circular_progress_with_text.dart';

class ExamResultScreen extends StatefulWidget {
  final ExamModel? exam;
  final StudentSubmissionModel? submission;

  const ExamResultScreen({super.key, this.exam, this.submission});

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  late ExamModel _exam;
  late StudentSubmissionModel _submission;

  String _filterMode = 'All'; // 'All', 'Incorrect', 'Skipped'
  Map<String, String> _selectedAnswers = {};
  bool _isLoading = true;
  int _userAttemptsCount = 1;
  bool _canRevealAnswers = true;

  @override
  void initState() {
    super.initState();
    _exam =
        widget.exam ??
        ExamModel(
          id: 'sample_id',
          examCode: 'EXM-2026-001',
          title: 'Assessment Evaluation',
          category: 'General',
          durationMinutes: 60,
          totalMarks: 50,
          passingScorePercentage: 60,
        );

    _submission =
        widget.submission ??
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

    _loadData();
  }

  Future<void> _loadData() async {
    // 1. If submission already carries answers, parse them
    if (_submission.answers.isNotEmpty) {
      _selectedAnswers = Map<String, String>.from(
        _submission.answers.map((k, v) => MapEntry(k, v.toString())),
      );
    } else if (_exam.id.isNotEmpty && _submission.id.isNotEmpty) {
      // Otherwise fetch submission answers from Firestore
      try {
        final subDoc = await FirebaseFirestore.instance
            .collection('exams')
            .doc(_exam.id)
            .collection('submissions')
            .doc(_submission.id)
            .get();

        if (subDoc.exists && subDoc.data() != null) {
          final rawMap =
              (subDoc.data()!['answers'] ?? subDoc.data()!['selectedAnswers'])
                  as Map<String, dynamic>?;
          if (rawMap != null) {
            _selectedAnswers = rawMap.map(
              (key, value) => MapEntry(key, value.toString()),
            );
          }
        }
      } catch (_) {}
    }

    // 2. If exam questions list is empty, fetch full exam document from Firestore
    if (_exam.questions.isEmpty && _exam.id.isNotEmpty) {
      try {
        final examDoc = await FirebaseFirestore.instance
            .collection('exams')
            .doc(_exam.id)
            .get();

        if (examDoc.exists) {
          _exam = ExamModel.fromFirestore(examDoc);
        }
      } catch (_) {}
    }

    // 3. Count attempts completed by this user to determine if answers should be revealed
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? _submission.studentId;
    if (currentUid.isNotEmpty && _exam.id.isNotEmpty) {
      try {
        final examSubs = await FirebaseFirestore.instance
            .collection('exams')
            .doc(_exam.id)
            .collection('submissions')
            .where('userId', isEqualTo: currentUid)
            .get();

        int count = examSubs.docs.length;
        if (count == 0) {
          final examSubsByStudentId = await FirebaseFirestore.instance
              .collection('exams')
              .doc(_exam.id)
              .collection('submissions')
              .where('studentId', isEqualTo: currentUid)
              .get();
          count = examSubsByStudentId.docs.length;
        }

        if (count == 0) {
          final userAttempts = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .collection('attempts')
              .where('examId', isEqualTo: _exam.id)
              .get();
          count = userAttempts.docs.length;
        }

        if (count > 0) {
          _userAttemptsCount = count;
        }
      } catch (_) {}
    }

    final bool isClosed = _exam.isClosed;
    final bool allAttemptsCompleted =
        _userAttemptsCount >= _exam.allowedAttempts;
    _canRevealAnswers =
        (_exam.allowedAttempts <= 1) || allAttemptsCompleted || isClosed;

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleNavigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigator()),
        (route) => false,
      );
    }
  }

  String _getOptionLetter(QuestionModel question, String optionId) {
    final index = question.options.indexWhere((o) => o.id == optionId);
    if (index != -1) {
      return String.fromCharCode(65 + index);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isDark
        ? const Color(0xFF0F0E17)
        : const Color(0xFFF8FAFC);
    final containerColor = isDark
        ? const Color(0xFF1E1B4B).withOpacity(0.35)
        : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F0E17);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFF2E2B52)
        : const Color(0xFFE2E8F0);

    final isPassed = _submission.isPassed;
    final scoreRatio = (_submission.scorePercentage / 100).clamp(0.0, 1.0);

    // Build evaluated questions list for scrolling review
    final List<Map<String, dynamic>> evaluatedQuestions = [];
    for (int i = 0; i < _exam.questions.length; i++) {
      final q = _exam.questions[i];
      final studentChoice = _selectedAnswers[q.id];
      final isSkipped = studentChoice == null || studentChoice.trim().isEmpty;
      final isCorrect = !isSkipped && studentChoice == q.correctOptionId;

      bool include = true;
      if (_filterMode == 'Incorrect' && _canRevealAnswers) {
        include = !isCorrect && !isSkipped;
      } else if (_filterMode == 'Skipped') {
        include = isSkipped;
      }

      if (include) {
        evaluatedQuestions.add({
          'index': i + 1,
          'question': q,
          'isCorrect': isCorrect,
          'isSkipped': isSkipped,
          'studentChoice': studentChoice,
        });
      }
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF131127) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
          ),
          onPressed: _handleNavigateBack,
          tooltip: "Back to Dashboard",
        ),
        title: Text(
          'Assessment Result',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title
                    Text(
                      'Performance Summary',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _exam.title,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Score Overview Card (Side by Side Row)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.2 : 0.03,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Column: Status Badge + Marks Secured
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status Badge (Passed / Needs Improvement)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPassed
                                        ? (isDark
                                              ? const Color(0xFF064E3B)
                                              : const Color(0xFFD1FAE5))
                                        : (isDark
                                              ? const Color(0xFF451A03)
                                              : const Color(0xFFFEF2F2)),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    isPassed ? 'PASSED' : 'NEEDS IMPROVEMENT',
                                    style: TextStyle(
                                      color: isPassed
                                          ? (isDark
                                                ? const Color(0xFF34D399)
                                                : const Color(0xFF065F46))
                                          : const Color(0xFFDC2626),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Marks Secured
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _submission.marksObtained.toStringAsFixed(
                                        _submission.marksObtained
                                                    .truncateToDouble() ==
                                                _submission.marksObtained
                                            ? 0
                                            : 1,
                                      ),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '/${_submission.totalMarks.toInt()}',
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Marks Secured',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Right Side: Circular Progress with Score Percentage
                          CustomCircularProgress(
                            progress: scoreRatio,
                            text: '${_submission.scorePercentage.toInt()}%',
                            width: 100,
                            height: 100,
                            circleSize: 100,
                            strokeWidth: 9,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stat Metrics: Correct, Incorrect, Skipped
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            Icons.check_circle_rounded,
                            const Color(0xFF10B981),
                            '${_submission.correctAnswers}',
                            'CORRECT',
                            containerColor,
                            textColor,
                            borderColor,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            Icons.cancel_rounded,
                            const Color(0xFFEF4444),
                            '${_submission.incorrectAnswers}',
                            'INCORRECT',
                            containerColor,
                            textColor,
                            borderColor,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            Icons.remove_circle_outline_rounded,
                            const Color(0xFF64748B),
                            '${_submission.unattemptedAnswers}',
                            'SKIPPED',
                            containerColor,
                            textColor,
                            borderColor,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    // Divider with Section Header
                    Row(
                      children: [
                        Icon(
                          Icons.fact_check_rounded,
                          color: isDark
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF7C3AED),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Question Review & Solutions',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _canRevealAnswers
                          ? 'Scroll down to review each question, your answers, and verified correct solutions.'
                          : 'Scroll down to review the questions and your recorded choices.',
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Notice if answers are locked for multiple attempts
                    if (!_canRevealAnswers) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF451A03).withOpacity(0.35)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_clock_rounded,
                              color: Color(0xFFF59E0B),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Answers Locked • Attempt $_userAttemptsCount of ${_exam.allowedAttempts}',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFF92400E),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'This exam allows multiple attempts (${_exam.allowedAttempts} max). Correct answers and verified solutions will be revealed once all attempts are completed or when the exam closes.',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFFDE68A)
                                              .withOpacity(0.85)
                                          : const Color(0xFFB45309),
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Filter Chips (All, Incorrect [if revealed], Skipped)
                    Row(
                      children: [
                        _buildFilterChip(
                          title: 'All (${_exam.questions.length})',
                          isSelected: _filterMode == 'All',
                          selectedColor: const Color(0xFF7C3AED),
                          textColor: textColor,
                          containerColor: containerColor,
                          borderColor: borderColor,
                          isDark: isDark,
                          onTap: () => setState(() => _filterMode = 'All'),
                        ),
                        if (_canRevealAnswers) ...[
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            title:
                                'Incorrect (${_submission.incorrectAnswers})',
                            isSelected: _filterMode == 'Incorrect',
                            selectedColor: const Color(0xFFEF4444),
                            textColor: textColor,
                            containerColor: containerColor,
                            borderColor: borderColor,
                            isDark: isDark,
                            onTap: () =>
                                setState(() => _filterMode = 'Incorrect'),
                          ),
                        ],
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          title: 'Skipped (${_submission.unattemptedAnswers})',
                          isSelected: _filterMode == 'Skipped',
                          selectedColor: const Color(0xFF64748B),
                          textColor: textColor,
                          containerColor: containerColor,
                          borderColor: borderColor,
                          isDark: isDark,
                          onTap: () => setState(() => _filterMode = 'Skipped'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Questions & Answers List
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      )
                    else if (evaluatedQuestions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 36.0,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text(
                            _filterMode == 'All'
                                ? 'No questions recorded for this assessment.'
                                : 'No $_filterMode questions found!',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: evaluatedQuestions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, idx) {
                          final item = evaluatedQuestions[idx];
                          final q = item['question'] as QuestionModel;
                          final qNum = item['index'] as int;
                          final isCorrect = item['isCorrect'] as bool;
                          final isSkipped = item['isSkipped'] as bool;
                          final studentChoice =
                              item['studentChoice'] as String?;

                          final studentLetter = studentChoice != null
                              ? _getOptionLetter(q, studentChoice)
                              : '';
                          final correctLetter = _getOptionLetter(
                            q,
                            q.correctOptionId,
                          );

                          return _buildQuestionCard(
                            questionNum: 'Question $qNum',
                            subject: q.category.isNotEmpty
                                ? q.category
                                : _exam.category,
                            marks: q.marks,
                            isCorrect: isCorrect,
                            isSkipped: isSkipped,
                            canRevealAnswers: _canRevealAnswers,
                            question: q,
                            studentChoice: studentChoice,
                            studentLetter: studentLetter,
                            correctLetter: correctLetter,
                            containerColor: containerColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            borderColor: borderColor,
                            isDark: isDark,
                          );
                        },
                      ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          );
        },
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
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String title,
    required bool isSelected,
    required Color selectedColor,
    required Color textColor,
    required Color containerColor,
    required Color borderColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : containerColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? Colors.transparent : borderColor,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : textColor),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required String questionNum,
    required String subject,
    required double marks,
    required bool isCorrect,
    required bool isSkipped,
    required bool canRevealAnswers,
    required QuestionModel question,
    required String? studentChoice,
    required String studentLetter,
    required String correctLetter,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDark,
  }) {
    final statusColor = !canRevealAnswers
        ? (isSkipped ? const Color(0xFF64748B) : const Color(0xFF7C3AED))
        : (isCorrect
            ? const Color(0xFF10B981)
            : isSkipped
            ? const Color(0xFF64748B)
            : const Color(0xFFEF4444));

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 4.5)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Question number, subject chip, marks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        !canRevealAnswers
                            ? (isSkipped
                                ? Icons.remove_circle_outline_rounded
                                : Icons.radio_button_checked_rounded)
                            : (isCorrect
                                ? Icons.check_circle_rounded
                                : isSkipped
                                ? Icons.remove_circle_outline_rounded
                                : Icons.cancel_rounded),
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        questionNum,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subject,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFA78BFA)
                                : const Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${marks.toInt()} Mark${marks.toInt() == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Question Image (if attached)
              if (question.imageUrl != null &&
                  question.imageUrl!.trim().isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    AppImageView.showFullScreenViewer(
                      context,
                      question.imageUrl!,
                      title: '$questionNum Image',
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 140,
                      maxHeight: 320,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withOpacity(0.5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AppImageView(
                          imageSource: question.imageUrl,
                          fit: BoxFit.contain,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to zoom',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Question Statement
              Text(
                question.questionText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              // Descriptive Question or Options List
              if (question.type == 'Descriptive' ||
                  question.options.isEmpty) ...[
                Text(
                  'Your Submitted Answer:',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withOpacity(0.6)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    (studentChoice ?? '').trim().isEmpty
                        ? 'No answer submitted.'
                        : (studentChoice ?? ''),
                    style: TextStyle(
                      color: (studentChoice ?? '').trim().isEmpty
                          ? subtitleColor
                          : textColor,
                      fontSize: 13,
                      fontStyle: (studentChoice ?? '').trim().isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      height: 1.4,
                    ),
                  ),
                ),
              ] else ...[
                // MCQ Options
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: question.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, optIdx) {
                    final option = question.options[optIdx];
                    final letter = String.fromCharCode(65 + optIdx);
                    final isThisOptionCorrect =
                        option.id == question.correctOptionId;
                    final isThisOptionSelected = option.id == studentChoice;
                    final hasOptImage =
                        option.imageUrl != null &&
                        option.imageUrl!.trim().isNotEmpty;

                    Color optionBg;
                    Color optionBorder;
                    Widget? statusBadge;

                    if (canRevealAnswers) {
                      if (isThisOptionCorrect) {
                        optionBg = isDark
                            ? const Color(0xFF064E3B).withOpacity(0.35)
                            : const Color(0xFFDCFCE7);
                        optionBorder = const Color(0xFF10B981);
                        statusBadge = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isThisOptionSelected
                                  ? 'Your Choice (Correct)'
                                  : 'Correct Answer',
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      } else if (isThisOptionSelected) {
                        optionBg = isDark
                            ? const Color(0xFF451A03).withOpacity(0.35)
                            : const Color(0xFFFEE2E2);
                        optionBorder = const Color(0xFFEF4444);
                        statusBadge = const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cancel_rounded,
                              color: Color(0xFFEF4444),
                              size: 15,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Your Selection (Incorrect)',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      } else {
                        optionBg = isDark
                            ? const Color(0xFF1E293B).withOpacity(0.4)
                            : const Color(0xFFF8FAFC);
                        optionBorder = isDark
                            ? Colors.white10
                            : Colors.grey.shade200;
                      }
                    } else {
                      // Answers locked until all attempts completed
                      if (isThisOptionSelected) {
                        optionBg = isDark
                            ? const Color(0xFF7C3AED).withOpacity(0.18)
                            : const Color(0xFFF3E8FF);
                        optionBorder = const Color(0xFF7C3AED);
                        statusBadge = const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Color(0xFF7C3AED),
                              size: 15,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Your Selection (Recorded)',
                              style: TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      } else {
                        optionBg = isDark
                            ? const Color(0xFF1E293B).withOpacity(0.4)
                            : const Color(0xFFF8FAFC);
                        optionBorder = isDark
                            ? Colors.white10
                            : Colors.grey.shade200;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: optionBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: optionBorder,
                          width: (isThisOptionCorrect || isThisOptionSelected)
                              ? 1.5
                              : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isThisOptionCorrect
                                      ? const Color(0xFF10B981)
                                      : (isThisOptionSelected
                                            ? const Color(0xFFEF4444)
                                            : (isDark
                                                  ? Colors.white12
                                                  : Colors.grey.shade300)),
                                ),
                                child: Center(
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      color:
                                          (isThisOptionCorrect ||
                                              isThisOptionSelected)
                                          ? Colors.white
                                          : textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  option.text.isNotEmpty
                                      ? option.text
                                      : 'Option $letter',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13.5,
                                    fontWeight:
                                        (isThisOptionCorrect ||
                                            isThisOptionSelected)
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (hasOptImage) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                AppImageView.showFullScreenViewer(
                                  context,
                                  option.imageUrl!,
                                  title: 'Option $letter Image',
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  minHeight: 90,
                                  maxHeight: 180,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AppImageView(
                                      imageSource: option.imageUrl,
                                      fit: BoxFit.contain,
                                    ),
                                    Positioned(
                                      right: 6,
                                      bottom: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.65),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.zoom_in_rounded,
                                              color: Colors.white,
                                              size: 11,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Zoom',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (statusBadge != null) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 36),
                              child: statusBadge,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),

              // Summary / Resolution Note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withOpacity(0.5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      canRevealAnswers
                          ? Icons.lightbulb_outline_rounded
                          : Icons.lock_clock_rounded,
                      color: canRevealAnswers
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFFF59E0B),
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        !canRevealAnswers
                            ? 'The correct answer is locked. Verified solutions will be revealed after all ${_exam.allowedAttempts} attempts are completed.'
                            : (isCorrect
                                ? 'Great job! You selected Option $correctLetter, which is the verified answer.'
                                : isSkipped
                                ? 'You skipped this question. Option $correctLetter is the verified correct answer.'
                                : 'You chose Option $studentLetter. The correct answer is Option $correctLetter.'),
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
