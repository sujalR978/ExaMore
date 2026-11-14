// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/user/screens/exam_result_screen.dart';
import 'package:prep_mate/features/user/services/exam_cache_service.dart';

class ActiveExamScreen extends StatefulWidget {
  final ExamModel exam;

  const ActiveExamScreen({super.key, required this.exam});

  @override
  State<ActiveExamScreen> createState() => _ActiveExamScreenState();
}

class _ActiveExamScreenState extends State<ActiveExamScreen>
    with WidgetsBindingObserver {
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late List<QuestionModel> _questions;
  int _currentIndex = 0;
  final Map<String, String> _selectedAnswers = {}; // { questionId: optionId }
  final Set<String> _markedForReview = {}; // { questionId }

  late int _remainingSeconds;
  Timer? _timer;
  bool _isSubmitting = false;

  int _appSwitchCount = 0;
  static const int maxAllowedSwitches = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _questions = List.from(widget.exam.questions);

    // Shuffle if enabled by admin
    if (widget.exam.shuffleQuestions) {
      _questions.shuffle();
    }

    _remainingSeconds = widget.exam.durationMinutes * 60;
    _restoreCachedProgress();
  }

  Future<void> _restoreCachedProgress() async {
    final cached = await ExamCacheService.getExamState(widget.exam.id);
    if (cached != null && mounted) {
      if (cached['isExpired'] == true) {
        _submitExam(isAutoSubmit: true);
        return;
      }
      setState(() {
        _remainingSeconds = cached['remainingSeconds'] as int;
        _selectedAnswers.addAll(cached['selectedAnswers'] as Map<String, String>);
        _appSwitchCount = cached['switchCount'] as int;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resumed in-progress exam from saved session.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.teal,
        ),
      );
    }
    _startTimer();
  }

  void _persistProgress() {
    ExamCacheService.saveExamState(
      examId: widget.exam.id,
      remainingSeconds: _remainingSeconds,
      selectedAnswers: _selectedAnswers,
      switchCount: _appSwitchCount,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _appSwitchCount++;
      _persistProgress();
    } else if (state == AppLifecycleState.resumed) {
      if (_appSwitchCount >= maxAllowedSwitches) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Maximum screen switch limit exceeded. Exam auto-submitting...',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        _submitExam(isAutoSubmit: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Warning: Leaving the exam is recorded. Screen switch count: $_appSwitchCount / $maxAllowedSwitches',
            ),
            backgroundColor: Colors.amber.shade900,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds % 5 == 0) {
          _persistProgress();
        }
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
    _persistProgress();
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
    await ExamCacheService.clearExamState(widget.exam.id);

    try {
      final studentId =
          _currentUser?.uid ??
          'STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final studentName = _currentUser?.displayName ?? 'Student User';
      final studentPhoto = _currentUser?.photoURL;

      // Fetch student's assigned adminId from Firestore
      String? studentAdminId;
      if (_currentUser?.uid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        studentAdminId = userDoc.data()?['adminId'];
      }

      final submission = await _examService.submitExamAttempt(
        examId: widget.exam.id,
        exam: widget.exam,
        studentId: studentId,
        studentName: studentName,
        studentAdminId: studentAdminId,
        studentImageUrl: studentPhoto,
        selectedAnswers: _selectedAnswers,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              ExamResultScreen(exam: widget.exam, submission: submission),
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

  void _showSubmissionConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final total = _questions.length;
    final answered = _selectedAnswers.length;
    final unanswered = total - answered;
    final marked = _markedForReview.length;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF7C3AED)),
            SizedBox(width: 10),
            Text('Submit Assessment?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review your summary before submitting. Answers cannot be modified after submission.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Questions', '$total', Icons.help_outline),
                  const Divider(height: 10),
                  _buildSummaryRow(
                    'Answered',
                    '$answered',
                    Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                  ),
                  const Divider(height: 10),
                  _buildSummaryRow(
                    'Unanswered',
                    '$unanswered',
                    Icons.radio_button_unchecked,
                    color: Colors.grey,
                  ),
                  if (marked > 0) ...[
                    const Divider(height: 10),
                    _buildSummaryRow(
                      'Marked for Review',
                      '$marked',
                      Icons.bookmark_outline,
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                  const Divider(height: 10),
                  _buildSummaryRow(
                    'Remaining Time',
                    _formatTimer(_remainingSeconds),
                    Icons.access_time_outlined,
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Review Test'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _submitExam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showQuestionPallet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        final surfaceColor = theme.colorScheme.surface;
        final textColor = theme.colorScheme.onSurface;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question Pallet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '${_selectedAnswers.length}/${_questions.length} Answered',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Legend
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildLegendPill(
                        color: const Color(0xFF10B981),
                        label: 'Answered (${_selectedAnswers.length})',
                      ),
                      _buildLegendPill(
                        color: const Color(0xFFF59E0B),
                        label: 'Flagged (${_markedForReview.length})',
                      ),
                      _buildLegendPill(
                        color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                        label: 'Skipped (${_questions.length - _selectedAnswers.length})',
                        textColor: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Expanded(
                    child: GridView.builder(
                      itemCount: _questions.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (gridCtx, idx) {
                        final q = _questions[idx];
                        final isAnswered = _selectedAnswers.containsKey(q.id);
                        final isMarked = _markedForReview.contains(q.id);
                        final isCurrent = idx == _currentIndex;

                        Color bg = isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade100;
                        Color textC = isDarkMode ? Colors.white70 : Colors.black87;
                        if (isAnswered) {
                          bg = const Color(0xFF10B981);
                          textC = Colors.white;
                        } else if (isMarked) {
                          bg = const Color(0xFFF59E0B);
                          textC = Colors.white;
                        }

                        return InkWell(
                          onTap: () {
                            setState(() => _currentIndex = idx);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFF7C3AED)
                                    : (isMarked ? const Color(0xFFF59E0B) : Colors.transparent),
                                width: isCurrent ? 2.5 : 1,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: textC,
                                  ),
                                ),
                                if (isMarked && isAnswered)
                                  const Positioned(
                                    top: 3,
                                    right: 3,
                                    child: Icon(
                                      Icons.star,
                                      size: 11,
                                      color: Color(0xFFFBBF24),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegendPill({
    required Color color,
    required String label,
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
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
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          tooltip: 'Exit Assessment',
          onPressed: () => _showSubmissionConfirmationDialog(context),
        ),
        title: Text(
          widget.exam.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          // Question Pallet Button with answered badge
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.grid_view_rounded, color: textColor, size: 22),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '${_selectedAnswers.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Question Pallet',
            onPressed: () => _showQuestionPallet(context),
          ),
          const SizedBox(width: 4),

          // Timer Pill
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 300
                      ? Colors.red.withOpacity(0.18)
                      : (isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFEDE9FE)),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _remainingSeconds < 300
                        ? Colors.redAccent
                        : const Color(0xFF7C3AED).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: _remainingSeconds < 300
                          ? Colors.redAccent
                          : const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatTimer(_remainingSeconds),
                      style: TextStyle(
                        color: _remainingSeconds < 300
                            ? Colors.redAccent
                            : const Color(0xFF7C3AED),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF7C3AED)),
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
                      // Flag Question Button
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (_markedForReview.contains(currentQuestion.id)) {
                              _markedForReview.remove(currentQuestion.id);
                            } else {
                              _markedForReview.add(currentQuestion.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _markedForReview.contains(currentQuestion.id)
                                ? const Color(0xFFF59E0B).withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  _markedForReview.contains(currentQuestion.id)
                                  ? const Color(0xFFF59E0B)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _markedForReview.contains(currentQuestion.id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 14,
                                color:
                                    _markedForReview.contains(
                                      currentQuestion.id,
                                    )
                                    ? const Color(0xFFF59E0B)
                                    : subtitleColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _markedForReview.contains(currentQuestion.id)
                                    ? 'Flagged'
                                    : 'Flag Question',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _markedForReview.contains(
                                        currentQuestion.id,
                                      )
                                      ? const Color(0xFFF59E0B)
                                      : subtitleColor,
                                ),
                              ),
                            ],
                          ),
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

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDarkMode ? 0.2 : 0.02,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                        ...currentQuestion.options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          final isSelected = selectedOptionId == option.id;

                          final String optionLetter = String.fromCharCode(
                            65 + index,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildOptionItem(
                              optionLetter: optionLetter,
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
                                Icon(
                                  Icons.arrow_back,
                                  size: 18,
                                  color: textColor,
                                ),
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
                              : () => _showSubmissionConfirmationDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _currentIndex == _questions.length - 1
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF7C3AED),
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
                                    : Icons.check_circle_outline,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentIndex < _questions.length - 1) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showSubmissionConfirmationDialog(context),
                        icon: const Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        label: const Text(
                          'Submit Assessment Early',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildOptionItem({
    required String optionLetter,
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
                  optionLetter,
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
