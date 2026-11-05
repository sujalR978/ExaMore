// ignore_for_file: deprecated_member_use, file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';

class ReviewAnswersScreen extends StatefulWidget {
  final ExamModel? exam;
  final StudentSubmissionModel? submission;

  const ReviewAnswersScreen({super.key, this.exam, this.submission});

  @override
  State<ReviewAnswersScreen> createState() => _ReviewAnswersScreenState();
}

class _ReviewAnswersScreenState extends State<ReviewAnswersScreen> {
  late ExamModel _exam;
  late StudentSubmissionModel _submission;

  String _filterMode = 'All'; // 'All', 'Incorrect', 'Skipped'
  Map<String, String> _selectedAnswers = {};
  bool _isLoadingAnswers = true;

  @override
  void initState() {
    super.initState();
    _exam =
        widget.exam ??
        ExamModel(
          id: '',
          examCode: 'EXM-2026',
          title: 'Assessment Review',
          category: 'General',
          durationMinutes: 60,
          totalMarks: 100,
          questions: [],
        );

    _submission =
        widget.submission ??
        StudentSubmissionModel(
          id: '',
          studentName: 'Student',
          studentId: 'STU-001',
          examTitle: _exam.title,
          scorePercentage: 0,
          marksObtained: 0,
          isPassed: false,
          submittedAt: DateTime.now(),
        );

    _fetchSubmissionAnswers();
  }

  Future<void> _fetchSubmissionAnswers() async {
    // If the submission object already carries answers, use them directly
    if (_submission.answers.isNotEmpty) {
      setState(() {
        _selectedAnswers = Map<String, String>.from(_submission.answers);
        _isLoadingAnswers = false;
      });
      return;
    }

    if (_exam.id.isEmpty || _submission.id.isEmpty) {
      setState(() => _isLoadingAnswers = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('exams')
          .doc(_exam.id)
          .collection('submissions')
          .doc(_submission.id)
          .get();

      if (doc.exists && doc.data() != null) {
        final rawMap =
            (doc.data()!['answers'] ?? doc.data()!['selectedAnswers'])
                as Map<String, dynamic>?;
        if (rawMap != null) {
          _selectedAnswers = rawMap.map(
            (key, value) => MapEntry(key, value.toString()),
          );
        }
      }
    } catch (_) {
      // Fallback
    } finally {
      if (mounted) {
        setState(() => _isLoadingAnswers = false);
      }
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
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    final List<Map<String, dynamic>> evaluatedQuestions = [];

    for (int i = 0; i < _exam.questions.length; i++) {
      final q = _exam.questions[i];
      final studentChoice = _selectedAnswers[q.id];

      final isSkipped = studentChoice == null || studentChoice.isEmpty;
      final isCorrect = !isSkipped && studentChoice == q.correctOptionId;

      bool include = true;
      if (_filterMode == 'Incorrect') {
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
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Review Answers',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoadingAnswers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Toggle Chips (All, Incorrect, Skipped)
                  Row(
                    children: [
                      _buildFilterChip(
                        title: 'All (${_exam.questions.length})',
                        isSelected: _filterMode == 'All',
                        selectedColor: const Color(0xFF1E1B4B),
                        textColor: textColor,
                        containerColor: containerColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                        onTap: () => setState(() => _filterMode = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        title: 'Incorrect (${_submission.incorrectAnswers})',
                        isSelected: _filterMode == 'Incorrect',
                        selectedColor: const Color(0xFFEF4444),
                        textColor: textColor,
                        containerColor: containerColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                        onTap: () => setState(() => _filterMode = 'Incorrect'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        title: 'Skipped (${_submission.unattemptedAnswers})',
                        isSelected: _filterMode == 'Skipped',
                        selectedColor: const Color(0xFF64748B),
                        textColor: textColor,
                        containerColor: containerColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                        onTap: () => setState(() => _filterMode = 'Skipped'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (evaluatedQuestions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text(
                          _filterMode == 'All'
                              ? 'No questions to review in this assessment.'
                              : 'No $_filterMode questions found!',
                          style: TextStyle(color: subtitleColor, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: evaluatedQuestions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, idx) {
                        final item = evaluatedQuestions[idx];
                        final q = item['question'] as QuestionModel;
                        final qNum = item['index'] as int;
                        final isCorrect = item['isCorrect'] as bool;
                        final isSkipped = item['isSkipped'] as bool;
                        final studentChoice = item['studentChoice'] as String?;

                        final studentLetter = studentChoice != null
                            ? _getOptionLetter(q, studentChoice)
                            : '';
                        final correctLetter = _getOptionLetter(
                          q,
                          q.correctOptionId,
                        );

                        return _buildQuestionCardWithOptions(
                          questionNum: 'Question $qNum',
                          subject: q.category.isNotEmpty
                              ? q.category
                              : _exam.category,
                          marks: q.marks,
                          isCorrect: isCorrect,
                          isSkipped: isSkipped,
                          question: q,
                          studentChoice: studentChoice,
                          studentLetter: studentLetter,
                          correctLetter: correctLetter,
                          containerColor: containerColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          borderColor: borderColor,
                          isDarkMode: isDarkMode,
                        );
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
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
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                    : (isDarkMode ? Colors.white70 : textColor),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCardWithOptions({
    required String questionNum,
    required String subject,
    required double marks,
    required bool isCorrect,
    required bool isSkipped,
    required QuestionModel question,
    required String? studentChoice,
    required String studentLetter,
    required String correctLetter,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    final statusColor = isCorrect
        ? const Color(0xFF10B981)
        : isSkipped
        ? const Color(0xFF64748B)
        : const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 5)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Question number, subject tag, marks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect
                            ? Icons.check_circle
                            : isSkipped
                            ? Icons.remove_circle_outline
                            : Icons.cancel,
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
                          color: isDarkMode
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subject,
                          style: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFF93C5FD)
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

              // Question Statement
              Text(
                question.questionText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Renders all 4 options
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: question.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, optIdx) {
                  final option = question.options[optIdx];
                  final letter = String.fromCharCode(65 + optIdx);
                  final isThisOptionCorrect =
                      option.id == question.correctOptionId;
                  final isThisOptionSelected = option.id == studentChoice;

                  Color optionBg;
                  Color optionBorder;
                  Widget? statusBadge;

                  if (isThisOptionCorrect) {
                    // Correct Option
                    optionBg = isDarkMode
                        ? const Color(0xFF064E3B).withOpacity(0.35)
                        : const Color(0xFFDCFCE7);
                    optionBorder = const Color(0xFF10B981);
                    statusBadge = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 16,
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
                    // Incorrect Choice selected by Student
                    optionBg = isDarkMode
                        ? const Color(0xFF451A03).withOpacity(0.35)
                        : const Color(0xFFFEE2E2);
                    optionBorder = const Color(0xFFEF4444);
                    statusBadge = const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          color: Color(0xFFEF4444),
                          size: 16,
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
                    // Default unselected Option
                    optionBg = isDarkMode
                        ? const Color(0xFF1E293B).withOpacity(0.5)
                        : const Color(0xFFF8FAFC);
                    optionBorder = isDarkMode
                        ? Colors.white10
                        : Colors.grey.shade200;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: optionBg,
                      borderRadius: BorderRadius.circular(12),
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
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isThisOptionCorrect
                                    ? const Color(0xFF10B981)
                                    : (isThisOptionSelected
                                          ? const Color(0xFFEF4444)
                                          : (isDarkMode
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
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
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
                        if (statusBadge != null) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 40),
                            child: statusBadge,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Summary / Resolution Note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF1E293B).withOpacity(0.6)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCorrect
                            ? 'Great job! You selected Option $correctLetter, which is the verified answer.'
                            : isSkipped
                            ? 'You skipped this question. Option $correctLetter is the verified correct answer.'
                            : 'You chose Option $studentLetter. The correct answer is Option $correctLetter.',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                          height: 1.4,
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
