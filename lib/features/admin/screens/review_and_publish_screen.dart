// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/screens/add_multiple_choice_question_screen.dart';
import 'package:prep_mate/features/admin/screens/admin_home_screen.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/admin/widgets/exam_stepper_header.dart';

class ReviewAndPublishScreen extends StatefulWidget {
  final ExamModel? exam;

  const ReviewAndPublishScreen({super.key, this.exam});

  @override
  State<ReviewAndPublishScreen> createState() => _ReviewAndPublishScreenState();
}

class _ReviewAndPublishScreenState extends State<ReviewAndPublishScreen> {
  final ExamService _examService = ExamService();

  late ExamModel _currentExam;
  late bool _shuffleQuestions;
  late bool _showResultsImmediately;
  late double _passingScorePercentage;

  bool _isSavingDraft = false;
  bool _isPublishing = false;

  double get _totalAllocatedMarks =>
      _currentExam.questions.fold(0.0, (total, q) => total + q.marks);

  @override
  void initState() {
    super.initState();
    _currentExam =
        widget.exam ??
        ExamModel(
          id: '',
          examCode: '',
          title: 'Sample Exam',
          category: 'General',
          durationMinutes: 60,
          totalMarks: 50,
          passingScorePercentage: 50,
          questions: [],
        );

    _shuffleQuestions = _currentExam.shuffleQuestions;
    _showResultsImmediately = _currentExam.showResultsImmediately;
    _passingScorePercentage = _currentExam.passingScorePercentage;
  }

  ExamModel _prepareUpdatedExam({String? newStatus}) {
    return _currentExam.copyWith(
      shuffleQuestions: _shuffleQuestions,
      showResultsImmediately: _showResultsImmediately,
      passingScorePercentage: _passingScorePercentage,
      status: newStatus ?? _currentExam.status,
      updatedAt: DateTime.now(),
    );
  }

  // Opens an inline dialog to adjust passing percentage
  Future<void> _handleEditPassingPercentage() async {
    final controller = TextEditingController(
      text: _passingScorePercentage.toInt().toString(),
    );
    final formKey = GlobalKey<FormState>();

    final updatedValue = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Edit Passing Percentage',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Specify the minimum percentage score required to pass this exam.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  decoration: InputDecoration(
                    suffixText: '%',
                    prefixIcon: const Icon(Icons.percent, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a percentage';
                    }
                    final num = double.tryParse(value.trim());
                    if (num == null) {
                      return 'Enter a valid number';
                    }
                    if (num < 0 || num > 100) {
                      return 'Value must be between 0 and 100';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final parsed = double.tryParse(controller.text.trim());
                  Navigator.pop(ctx, parsed);
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (updatedValue != null && mounted) {
      setState(() {
        _passingScorePercentage = updatedValue;
        _currentExam = _currentExam.copyWith(
          passingScorePercentage: updatedValue,
        );
      });
    }
  }

  Future<void> _handleSaveDraft() async {
    setState(() => _isSavingDraft = true);
    try {
      final updatedExam = _prepareUpdatedExam(newStatus: 'Draft');
      await _examService.updateExam(updatedExam);
      _currentExam = updatedExam;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam draft saved successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save draft: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<void> _handlePublishExam() async {
    if (_currentExam.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question before publishing.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final updatedExam = _prepareUpdatedExam(newStatus: 'Published');
      await _examService.updateExam(updatedExam);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Exam published live! Students can now access it.'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish exam: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _handleAddMoreQuestions() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                AddMultipleChoiceQuestionScreen(exam: _prepareUpdatedExam()),
          ),
        )
        .then((_) => _refreshExamData());
  }

  void _handleEditQuestion(QuestionModel question, int index) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddMultipleChoiceQuestionScreen(
              exam: _prepareUpdatedExam(),
              editingQuestion: question,
              questionIndex: index,
            ),
          ),
        )
        .then((_) => _refreshExamData());
  }

  Future<void> _handleDeleteQuestion(int index) async {
    final updatedList = List<QuestionModel>.from(_currentExam.questions)
      ..removeAt(index);
    final updatedExam = _currentExam.copyWith(questions: updatedList);

    setState(() {
      _currentExam = updatedExam;
    });

    await _examService.updateExam(updatedExam);
  }

  Future<void> _refreshExamData() async {
    final stream = _examService.getExamStream(_currentExam.id);
    final latestExam = await stream.first;
    if (mounted) {
      setState(() {
        _currentExam = latestExam;
        _passingScorePercentage = latestExam.passingScorePercentage;
        _shuffleQuestions = latestExam.shuffleQuestions;
        _showResultsImmediately = latestExam.showResultsImmediately;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0);

    final isMarksMatched =
        _totalAllocatedMarks == _currentExam.totalMarks &&
            _currentExam.totalMarks > 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review & Publish',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Step 3 of 3 • Final Verification',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          ExamStepperHeader(currentStep: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD 1: EXAM OVERVIEW SUMMARY
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_outlined,
                                color: Color(0xFF7C3AED),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentExam.title.isEmpty
                                        ? 'Untitled Exam'
                                        : _currentExam.title,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (_currentExam.classroomName != null &&
                                          _currentExam.classroomName!.isNotEmpty)
                                        _buildTag(
                                          icon: Icons.school,
                                          text: _currentExam.classroomName!,
                                          color: const Color(0xFF7C3AED),
                                        ),
                                      _buildTag(
                                        icon: Icons.menu_book,
                                        text: _currentExam.category,
                                        color: const Color(0xFF10B981),
                                      ),
                                      _buildTag(
                                        icon: Icons.flag_outlined,
                                        text: _currentExam.status,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: borderColor, height: 1),
                        const SizedBox(height: 14),

                        // 4-Segment Metric Ribbon
                        Row(
                          children: [
                            _buildStatItem(
                              title: 'DURATION',
                              value: '${_currentExam.durationMinutes}m',
                              icon: Icons.access_time_rounded,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                            ),
                            _buildVerticalDivider(borderColor),
                            _buildStatItem(
                              title: 'TOTAL MARKS',
                              value: '${_currentExam.totalMarks.toInt()} pts',
                              icon: Icons.functions_rounded,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                            ),
                            _buildVerticalDivider(borderColor),
                            _buildStatItem(
                              title: 'QUESTIONS',
                              value: '${_currentExam.questions.length}',
                              icon: Icons.quiz_outlined,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                            ),
                            _buildVerticalDivider(borderColor),
                            _buildStatItem(
                              title: 'PASS SCORE',
                              value: '${_passingScorePercentage.toInt()}%',
                              icon: Icons.percent_rounded,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CARD 2: EVALUATION RULES & ANTI-CHEAT SETTINGS
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evaluation Rules & Settings',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Passing Score Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minimum Passing Score',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Score percentage required to pass',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: _handleEditPassingPercentage,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_passingScorePercentage.toInt()}%',
                                      style: const TextStyle(
                                        color: Color(0xFF7C3AED),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.edit,
                                      size: 13,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        Divider(color: borderColor, height: 20),

                        // Shuffle Questions Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shuffle Question Order',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Randomizes questions per student',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: _shuffleQuestions,
                              activeColor: const Color(0xFF7C3AED),
                              onChanged: (val) {
                                setState(() => _shuffleQuestions = val);
                              },
                            ),
                          ],
                        ),

                        Divider(color: borderColor, height: 20),

                        // Show Results Immediately Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Instant Results Visibility',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Show score immediately upon submission',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: _showResultsImmediately,
                              activeColor: const Color(0xFF7C3AED),
                              onChanged: (val) {
                                setState(() => _showResultsImmediately = val);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CARD 3: QUESTIONS REVIEW LIST
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions (${_currentExam.questions.length})',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _handleAddMoreQuestions,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Add More',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_currentExam.questions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 40,
                            color: subtitleColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No questions added yet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please add at least 1 question to publish this exam.',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentExam.questions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final q = _currentExam.questions[idx];

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: containerColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
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
                                      color: const Color(0xFF7C3AED)
                                          .withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(
                                          color: Color(0xFF7C3AED),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                      '${q.marks.toInt()} pt${q.marks > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    color: const Color(0xFF7C3AED),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _handleEditQuestion(q, idx),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                    ),
                                    color: Colors.redAccent,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _handleDeleteQuestion(idx),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                q.questionText,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...q.options.map((opt) {
                                final isCorrect =
                                    opt.id == q.correctOptionId;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: isCorrect
                                              ? const Color(0xFF10B981)
                                              : (isDarkMode
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFE2E8F0)),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: isCorrect
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.white,
                                                )
                                              : Text(
                                                  opt.id,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: subtitleColor,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          opt.text,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isCorrect
                                                ? const Color(0xFF10B981)
                                                : textColor,
                                            fontWeight: isCorrect
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  // Add Question Dashed Card
                  InkWell(
                    onTap: _handleAddMoreQuestions,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: Color(0xFF7C3AED),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '+ Add Another Question',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: containerColor,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: _isSavingDraft || _isPublishing
                      ? null
                      : _handleSaveDraft,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSavingDraft
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Save Draft',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _isSavingDraft || _isPublishing
                      ? null
                      : _handlePublishExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Publish Exam',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.rocket_launch_rounded, size: 16),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(Color borderColor) {
    return Container(width: 1, height: 30, color: borderColor);
  }
}
