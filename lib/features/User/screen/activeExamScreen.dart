import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';
import 'package:prep_mate/features/User/screen/examResultScreen.dart';


class ActiveExamScreen extends StatefulWidget {
  final ExamModel exam;

  const ActiveExamScreen({super.key, required this.exam});

  @override
  State<ActiveExamScreen> createState() => _ActiveExamScreenState();
}

class _ActiveExamScreenState extends State<ActiveExamScreen> {
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late List<QuestionModel> _questions;
  int _currentIndex = 0;
  final Map<String, String> _selectedAnswers = {}; // { questionId: optionId }

  late int _remainingSeconds;
  Timer? _timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.exam.questions);

    // Shuffle if enabled by admin
    if (widget.exam.shuffleQuestions) {
      _questions.shuffle();
    }

    _remainingSeconds = widget.exam.durationMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _submitExam(isAutoSubmit: true);
      }
    });
  }

  String _formatTimer(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _handleOptionSelect(String optionId) {
    if (_questions.isEmpty) return;
    setState(() {
      _selectedAnswers[_questions[_currentIndex].id] = optionId;
    });
  }

  void _handlePrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _handleNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  Future<void> _submitExam({bool isAutoSubmit = false}) async {
    if (_isSubmitting) return;

    _timer?.cancel();
    setState(() => _isSubmitting = true);

    try {
      final studentId = _currentUser?.uid ??
          'STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final studentName = _currentUser?.displayName ?? 'Student User';
      final studentPhoto = _currentUser?.photoURL;

      final submission = await _examService.submitExamAttempt(
        examId: widget.exam.id,
        exam: widget.exam,
        studentId: studentId,
        studentName: studentName,
        studentImageUrl: studentPhoto,
        selectedAnswers: _selectedAnswers,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ExamResultScreen(
            exam: widget.exam,
            submission: submission,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting exam: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleSubmitEarly(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Submit Exam Early?',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Are you sure you want to finish and submit your exam before the timer runs out? You cannot change your answers after submission.',
            style: TextStyle(
              color: isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _submitExam();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF1E1B4B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Yes, Submit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(widget.exam.title)),
        body: const Center(child: Text('No questions available in this exam.')),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final selectedOptionId = _selectedAnswers[currentQuestion.id];
    final progressValue = (_selectedAnswers.length / _questions.length);

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
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => _handleSubmitEarly(context),
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
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _remainingSeconds < 300
                              ? Colors.red.withOpacity(0.2)
                              : (isDarkMode
                                  ? const Color(0xFF312E81)
                                  : const Color(0xFFDBEAFE)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: _remainingSeconds < 300
                                  ? Colors.red
                                  : const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatTimer(_remainingSeconds),
                              style: TextStyle(
                                color: _remainingSeconds < 300
                                    ? Colors.red
                                    : (isDarkMode
                                        ? const Color(0xFF93C5FD)
                                        : const Color(0xFF1D4ED8)),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
          ),
        ),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting and evaluating your responses...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Progress Header & Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QUESTION ${_currentIndex + 1} OF ${_questions.length}',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${(progressValue * 100).toInt()}% Completed',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 8,
                      backgroundColor: isDarkMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Question Card Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Tag & Marks
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF312E81)
                                    : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.exam.category,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? const Color(0xFF93C5FD)
                                      : const Color(0xFF1D4ED8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${currentQuestion.marks.toStringAsFixed(0)} Marks',
                              style: TextStyle(
                                color: subtitleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Question Text
                        Text(
                          currentQuestion.questionText,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Dynamic Options
                        ...currentQuestion.options.map((option) {
                          final isSelected = selectedOptionId == option.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildOptionItem(
                              optionId: option.id,
                              text: option.text,
                              isSelected: isSelected,
                              isDarkMode: isDarkMode,
                              containerColor: containerColor,
                              textColor: textColor,
                              borderColor: borderColor,
                              onSelect: () => _handleOptionSelect(option.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Navigation Buttons Row (Previous & Next/Submit)
                  Row(
                    children: [
                      if (_currentIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _handlePrevious,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back,
                                    size: 18, color: textColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Previous',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_currentIndex > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentIndex < _questions.length - 1
                              ? _handleNext
                              : () => _handleSubmitEarly(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _currentIndex == _questions.length - 1
                                    ? const Color(0xFF10B981)
                                    : (isDarkMode
                                        ? const Color(0xFF312E81)
                                        : const Color(0xFF1E1B4B)),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex < _questions.length - 1
                                    ? 'Next Question'
                                    : 'Finish & Submit',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentIndex < _questions.length - 1
                                    ? Icons.arrow_forward
                                    : Icons.check,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Submit Exam Early Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _handleSubmitEarly(context),
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
                          Icon(Icons.check, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Submit Exam Early',
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

  Widget _buildOptionItem({
    required String optionId,
    required String text,
    required bool isSelected,
    required bool isDarkMode,
    required Color containerColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onSelect,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))
              : containerColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDarkMode
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF1E1B4B))
                : borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B))
                      : (isDarkMode
                          ? const Color(0xFF94A3B8)
                          : Colors.grey.shade400),
                  width: 1.5,
                ),
                color: isSelected
                    ? (isDarkMode
                        ? const Color(0xFF312E81)
                        : const Color(0xFF1E1B4B))
                    : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  optionId,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDarkMode
                            ? const Color(0xFF94A3B8)
                            : Colors.grey.shade600),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}