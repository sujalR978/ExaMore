import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';


class ReviewAnswersScreen extends StatefulWidget {
  final ExamModel? exam;
  final StudentSubmissionModel? submission;

  const ReviewAnswersScreen({
    super.key,
    this.exam,
    this.submission,
  });

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
    _exam = widget.exam ??
        ExamModel(
          id: '',
          examCode: 'EXM-2026',
          title: 'Assessment Review',
          category: 'General',
          durationMinutes: 60,
          totalMarks: 100,
          questions: [],
        );

    _submission = widget.submission ??
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
        final rawMap = doc.data()!['selectedAnswers'] as Map<String, dynamic>?;
        if (rawMap != null) {
          _selectedAnswers = rawMap.map(
            (key, value) => MapEntry(key, value.toString()),
          );
        }
      }
    } catch (_) {
      // Fallback to empty answers
    } finally {
      if (mounted) {
        setState(() => _isLoadingAnswers = false);
      }
    }
  }

  String _getOptionText(QuestionModel question, String optionId) {
    final match = question.options.where((o) => o.id == optionId);
    if (match.isNotEmpty) {
      return '$optionId. ${match.first.text}';
    }
    return optionId;
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

    // Filter questions based on student selections
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
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Review Answers',
                    style: TextStyle(
                      color: textColor,
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
                  // Top Summary Filter Cards (Incorrect & Skipped)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterMode = _filterMode == 'Incorrect'
                                  ? 'All'
                                  : 'Incorrect';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF451A03).withOpacity(0.4)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _filterMode == 'Incorrect'
                                    ? Colors.red
                                    : (isDarkMode
                                        ? Colors.red.withOpacity(0.3)
                                        : Colors.red.shade100),
                                width: _filterMode == 'Incorrect' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${_submission.incorrectAnswers}',
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _filterMode == 'Incorrect'
                                      ? 'Showing Incorrect'
                                      : 'Incorrect',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterMode = _filterMode == 'Skipped'
                                  ? 'All'
                                  : 'Skipped';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: containerColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _filterMode == 'Skipped'
                                    ? const Color(0xFF7C3AED)
                                    : borderColor,
                                width: _filterMode == 'Skipped' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${_submission.unattemptedAnswers}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _filterMode == 'Skipped'
                                      ? 'Showing Skipped'
                                      : 'Skipped',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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

                        final yourAnswerDisplay = !isSkipped
                            ? _getOptionText(q, studentChoice!)
                            : 'Skipped / Unattempted';

                        final correctAnswerDisplay =
                            _getOptionText(q, q.correctOptionId);

                        return _buildReviewCard(
                          questionNum: 'Question $qNum',
                          subject: q.category.isNotEmpty
                              ? q.category
                              : _exam.category,
                          isCorrect: isCorrect,
                          isSkipped: isSkipped,
                          questionText: q.questionText,
                          hasYourAnswer: !isSkipped,
                          yourAnswerText: yourAnswerDisplay,
                          correctAnswerText: correctAnswerDisplay,
                          explanationTitle: isCorrect
                              ? 'CORRECT ANSWER CONFIRMATION'
                              : 'EXPLANATION & CORRECTION',
                          explanationText: isCorrect
                              ? 'You selected option $studentChoice which accurately matches the answer key criteria.'
                              : isSkipped
                                  ? 'This question was left blank. The required answer is option ${q.correctOptionId}.'
                                  : 'Option $studentChoice is incorrect. Option ${q.correctOptionId} is the verified answer for this question.',
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

  Widget _buildReviewCard({
    required String questionNum,
    required String subject,
    required bool isCorrect,
    required bool isSkipped,
    required String questionText,
    required bool hasYourAnswer,
    String? yourAnswerText,
    required String correctAnswerText,
    required String explanationTitle,
    required String explanationText,
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
            border: Border(
              left: BorderSide(
                color: statusColor,
                width: 5,
              ),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row
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
                                : Icons.close,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
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
                ],
              ),
              const SizedBox(height: 12),
              // Question Text
              Text(
                questionText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Your Answer Box
              if (hasYourAnswer) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? (isDarkMode
                            ? const Color(0xFF064E3B).withOpacity(0.2)
                            : const Color(0xFFECFDF5))
                        : (isDarkMode
                            ? const Color(0xFF451A03).withOpacity(0.3)
                            : const Color(0xFFFEF2F2)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green.withOpacity(0.2)
                          : (isDarkMode
                              ? Colors.red.withOpacity(0.2)
                              : Colors.red.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR ANSWER',
                        style: TextStyle(
                          color: isCorrect
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        yourAnswerText ?? '',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Correct Answer Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF064E3B).withOpacity(0.3)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.green.withOpacity(0.2)
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CORRECT ANSWER',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            correctAnswerText,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF059669),
                      size: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Explanation Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF1E1B4B).withOpacity(0.5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF8B5CF6),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          explanationTitle,
                          style: const TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      explanationText,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        height: 1.4,
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