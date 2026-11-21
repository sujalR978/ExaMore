// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prep_mate/core/widgets/app_image_view.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/screens/review_and_publish_screen.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/admin/widgets/admin_top_bar.dart';
import 'package:prep_mate/features/admin/widgets/exam_stepper_header.dart';
import 'package:prep_mate/features/admin/widgets/question_option_tile.dart';

class AddMultipleChoiceQuestionScreen extends StatefulWidget {
  final ExamModel exam;
  final QuestionModel? editingQuestion;
  final int? questionIndex;
  final bool isForQuestionBank;

  const AddMultipleChoiceQuestionScreen({
    super.key,
    required this.exam,
    this.editingQuestion,
    this.questionIndex,
    this.isForQuestionBank = false,
  });

  @override
  State<AddMultipleChoiceQuestionScreen> createState() =>
      _AddMultipleChoiceQuestionScreenState();
}

class _AddMultipleChoiceQuestionScreenState
    extends State<AddMultipleChoiceQuestionScreen> {
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  late ExamModel _currentExam;
  late TextEditingController _questionController;
  late TextEditingController _marksController;
  late List<TextEditingController> _optionControllers;

  String _questionType = 'Multiple Choice';
  String? _questionImage;
  List<String?> _optionImages = [null, null, null, null];

  int _selectedCorrectOption = 0;
  int? _editingIndex;
  bool _isLoading = false;

  bool get _isEditingFromWidget => widget.editingQuestion != null;
  double get _totalAllocatedMarks =>
      _currentExam.questions.fold(0.0, (total, q) => total + q.marks);

  @override
  void initState() {
    super.initState();
    _currentExam = widget.exam;

    if (_isEditingFromWidget) {
      final q = widget.editingQuestion!;
      _editingIndex = widget.questionIndex;
      _questionType = q.type.isNotEmpty ? q.type : 'Multiple Choice';
      _questionImage = q.imageUrl;
      _questionController = TextEditingController(text: q.questionText);
      _marksController = TextEditingController(
        text: q.marks.toInt().toString(),
      );
      _optionControllers = q.options
          .map((opt) => TextEditingController(text: opt.text))
          .toList();
      _optionImages = q.options.map((opt) => opt.imageUrl).toList();
      while (_optionImages.length < _optionControllers.length) {
        _optionImages.add(null);
      }

      final correctIdx = q.options.indexWhere(
        (opt) => opt.id == q.correctOptionId,
      );
      _selectedCorrectOption = correctIdx >= 0 ? correctIdx : 0;
    } else {
      _questionController = TextEditingController();
      _marksController = TextEditingController(text: '1');
      _optionControllers = [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ];
      _optionImages = [null, null, null, null];
      _selectedCorrectOption = 0;
      _questionType = 'Multiple Choice';
      _questionImage = null;
    }
  }

  Future<void> _pickQuestionImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 900,
        maxHeight: 900,
      );
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        setState(() {
          _questionImage = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick question image: $e')),
        );
      }
    }
  }

  Future<void> _pickOptionImage(int index) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        setState(() {
          while (_optionImages.length <= index) {
            _optionImages.add(null);
          }
          _optionImages[index] = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick option image: $e')),
        );
      }
    }
  }

  /// Verifies whether the current user is an admin, super_admin, or teacher
  Future<bool> _checkAdminAccess() async {
    if (_currentUser == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      if (!doc.exists) return false;
      final role = (doc.data()?['role'] ?? '').toString().toLowerCase();
      return role == 'admin' || role == 'super_admin' || role == 'teacher';
    } catch (_) {
      // Fallback: allow authenticated admin on transient offline
      return true;
    }
  }

  void _resetForm() {
    _questionController.clear();
    _marksController.text = '1';
    for (var c in _optionControllers) {
      c.dispose();
    }
    _optionControllers = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    _optionImages = [null, null, null, null];
    _selectedCorrectOption = 0;
    _questionType = 'Multiple Choice';
    _questionImage = null;
  }

  void _startEditingQuestion(int index) {
    final q = _currentExam.questions[index];
    setState(() {
      _editingIndex = index;
      _questionType = q.type.isNotEmpty ? q.type : 'Multiple Choice';
      _questionImage = q.imageUrl;
      _questionController.text = q.questionText;
      _marksController.text = q.marks.toInt().toString();

      for (var c in _optionControllers) {
        c.dispose();
      }
      _optionControllers = q.options
          .map((opt) => TextEditingController(text: opt.text))
          .toList();
      _optionImages = q.options.map((opt) => opt.imageUrl).toList();
      while (_optionImages.length < _optionControllers.length) {
        _optionImages.add(null);
      }

      final correctIdx = q.options.indexWhere(
        (opt) => opt.id == q.correctOptionId,
      );
      _selectedCorrectOption = correctIdx >= 0 ? correctIdx : 0;
    });

    // Smooth scroll down to question form
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
      _resetForm();
    });
  }

  Future<void> _deleteQuestion(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete Question?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to remove this question from this exam?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final updatedQuestions = List<QuestionModel>.from(_currentExam.questions)
      ..removeAt(index);
    final updatedExam = _currentExam.copyWith(
      questions: updatedQuestions,
      updatedAt: DateTime.now(),
    );

    await _examService.updateExam(updatedExam);

    if (mounted) {
      setState(() {
        _currentExam = updatedExam;
        if (_editingIndex == index) {
          _editingIndex = null;
          _resetForm();
        } else if (_editingIndex != null && _editingIndex! > index) {
          _editingIndex = _editingIndex! - 1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question removed'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  QuestionModel? _buildQuestionFromInputs() {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter question text'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }

    final marks = double.tryParse(_marksController.text.trim()) ?? 1.0;

    String questionId;
    if (_editingIndex != null &&
        _editingIndex! < _currentExam.questions.length) {
      questionId = _currentExam.questions[_editingIndex!].id;
    } else if (_isEditingFromWidget) {
      questionId = widget.editingQuestion!.id;
    } else {
      questionId = DateTime.now().millisecondsSinceEpoch.toString();
    }

    if (_questionType == 'Descriptive') {
      return QuestionModel(
        id: questionId,
        questionText: questionText,
        marks: marks,
        options: [],
        correctOptionId: '',
        type: 'Descriptive',
        category: _currentExam.category,
        imageUrl: _questionImage,
        estimatedTimeMinutes: 3,
      );
    }

    final validOptions = <QuestionOption>[];
    for (int i = 0; i < _optionControllers.length; i++) {
      final text = _optionControllers[i].text.trim();
      final optionImg = i < _optionImages.length ? _optionImages[i] : null;

      if (text.isEmpty && (optionImg == null || optionImg.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter text or an image for Option ${String.fromCharCode(65 + i)}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return null;
      }
      validOptions.add(
        QuestionOption(
          id: String.fromCharCode(65 + i),
          text: text,
          imageUrl: optionImg,
        ),
      );
    }

    if (validOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 options are required for multiple choice'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }

    final selectedOptionLetter = String.fromCharCode(
      65 + _selectedCorrectOption,
    );

    return QuestionModel(
      id: questionId,
      questionText: questionText,
      marks: marks,
      options: validOptions,
      correctOptionId: selectedOptionLetter,
      type: 'Multiple Choice',
      category: _currentExam.category,
      imageUrl: _questionImage,
      estimatedTimeMinutes: 2,
    );
  }

  Future<bool> _saveCurrentQuestionToFirebase(QuestionModel question) async {
    setState(() => _isLoading = true);

    try {
      final hasAccess = await _checkAdminAccess();
      if (!hasAccess) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Access Denied: Only Admins can modify exams.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }

      // Question Bank Workflow
      if (widget.isForQuestionBank) {
        final bankQuestion = QuestionModel(
          id: question.id,
          questionText: question.questionText,
          marks: question.marks,
          options: question.options,
          correctOptionId: question.correctOptionId,
          type: question.type,
          category: _currentExam.category.isEmpty
              ? 'General'
              : _currentExam.category,
          difficulty: 'Medium',
          views: 0,
          estimatedTimeMinutes: question.estimatedTimeMinutes,
          createdAt: DateTime.now(),
        );

        await _examService.addQuestionToBank(bankQuestion);
        return true;
      }

      // Exam Workflow
      List<QuestionModel> updatedQuestions = List.from(_currentExam.questions);

      if (_editingIndex != null &&
          _editingIndex! < updatedQuestions.length) {
        updatedQuestions[_editingIndex!] = question;
      } else {
        updatedQuestions.add(question);
      }

      final assignedAdminId = _currentExam.adminId.isNotEmpty
          ? _currentExam.adminId
          : (_currentUser?.uid ?? '');

      final updatedExam = _currentExam.copyWith(
        adminId: assignedAdminId,
        questions: updatedQuestions,
        updatedAt: DateTime.now(),
      );

      if (updatedExam.id.isEmpty) {
        final newId = await _examService.createExamDraft(
          updatedExam,
          adminId: assignedAdminId,
        );
        _currentExam = updatedExam.copyWith(id: newId);
      } else {
        await _examService.updateExam(updatedExam);
        _currentExam = updatedExam;
      }

      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving question: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSaveQuestion({required bool andAddAnother}) async {
    final question = _buildQuestionFromInputs();
    if (question == null) return;

    final success = await _saveCurrentQuestionToFirebase(question);
    if (!success || !mounted) return;

    if (widget.isForQuestionBank) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question saved to Question Bank!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editingIndex != null ? 'Question updated!' : 'Question added to exam!',
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 1),
      ),
    );

    setState(() {
      _editingIndex = null;
      _resetForm();
    });
  }

  Future<void> _handleProceedToReview() async {
    // If there is un-saved text in question box, attempt to save it first
    if (_questionController.text.trim().isNotEmpty) {
      final question = _buildQuestionFromInputs();
      if (question != null) {
        final success = await _saveCurrentQuestionToFirebase(question);
        if (!success || !mounted) return;
        setState(() {
          _editingIndex = null;
          _resetForm();
        });
      }
    }

    if (!mounted) return;

    if (_currentExam.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 1 question to continue.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewAndPublishScreen(exam: _currentExam),
      ),
    );
  }

  void _handleAddOption() {
    if (_optionControllers.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 options allowed')),
      );
      return;
    }
    setState(() {
      _optionControllers.add(TextEditingController());
      _optionImages.add(null);
    });
  }

  void _handleRemoveOption(int index) {
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 2 options required')),
      );
      return;
    }
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      if (index < _optionImages.length) {
        _optionImages.removeAt(index);
      }
      if (_selectedCorrectOption >= _optionControllers.length) {
        _selectedCorrectOption = _optionControllers.length - 1;
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _marksController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
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
      appBar: AdminTopBar(
        title: widget.isForQuestionBank
            ? 'Question Bank'
            : (_editingIndex != null ? 'Edit Question' : 'Exam Questions'),
        subtitle: widget.isForQuestionBank
            ? 'Repository Question Item'
            : 'Step 2 of 3 • Add & Manage Questions',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          if (!widget.isForQuestionBank) ExamStepperHeader(currentStep: 2),

          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. EXAM SUMMARY & MARKS ALLOCATION STRIP
                  if (!widget.isForQuestionBank) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF7C3AED).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.assignment_outlined,
                                  color: Color(0xFF7C3AED),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${_currentExam.category} • ${_currentExam.durationMinutes} mins',
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isMarksMatched
                                      ? const Color(0xFF10B981).withOpacity(0.12)
                                      : const Color(0xFFF59E0B).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isMarksMatched
                                          ? Icons.check_circle_outline
                                          : Icons.info_outline,
                                      size: 13,
                                      color: isMarksMatched
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isMarksMatched
                                          ? 'Marks Matched'
                                          : '${_totalAllocatedMarks.toInt()} / ${_currentExam.totalMarks.toInt()} pts',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: isMarksMatched
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _currentExam.totalMarks > 0
                                  ? (_totalAllocatedMarks /
                                          _currentExam.totalMarks)
                                      .clamp(0.0, 1.0)
                                  : 0.0,
                              backgroundColor: isDarkMode
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isMarksMatched
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF7C3AED),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 2. LIST OF ADDED QUESTIONS (IF ANY)
                  if (!widget.isForQuestionBank &&
                      _currentExam.questions.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Added Questions (${_currentExam.questions.length})',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tap pencil to edit',
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentExam.questions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final q = _currentExam.questions[idx];
                        final isEditingThis = _editingIndex == idx;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isEditingThis
                                ? const Color(0xFF7C3AED).withOpacity(0.08)
                                : containerColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isEditingThis
                                  ? const Color(0xFF7C3AED)
                                  : borderColor,
                              width: isEditingThis ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED)
                                          .withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(
                                          color: Color(0xFF7C3AED),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
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
                                  if (q.type == 'Descriptive') ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Descriptive',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (q.imageUrl != null &&
                                      q.imageUrl!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0EA5E9)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.image,
                                            size: 11,
                                            color: Color(0xFF0EA5E9),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Image',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0EA5E9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    color: const Color(0xFF7C3AED),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Edit Question',
                                    onPressed: () => _startEditingQuestion(idx),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                    ),
                                    color: Colors.redAccent,
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Delete Question',
                                    onPressed: () => _deleteQuestion(idx),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                q.questionText,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (q.type == 'Descriptive')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Descriptive: Student writes text response during assessment',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: subtitleColor,
                                    ),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: q.options.map((opt) {
                                    final isCorrect =
                                        opt.id == q.correctOptionId;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCorrect
                                            ? const Color(0xFF10B981)
                                                .withOpacity(0.12)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isCorrect
                                              ? const Color(0xFF10B981)
                                              : borderColor,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isCorrect) ...[
                                            const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Color(0xFF10B981),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            '${opt.id}. ${opt.text}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isCorrect
                                                  ? const Color(0xFF10B981)
                                                  : subtitleColor,
                                              fontWeight: isCorrect
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 3. THE QUESTION BUILDER FORM CARD
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                          blurRadius: 10,
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.quiz_outlined,
                                    color: Color(0xFF7C3AED),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _editingIndex != null
                                      ? 'Edit Question #${_editingIndex! + 1}'
                                      : '+ Add New Question',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (_editingIndex != null)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _cancelEditing,
                                icon: const Icon(Icons.close, size: 14),
                                label: const Text('Cancel Edit'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Question Type Switcher
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Type:',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Multiple Choice'),
                              selected: _questionType == 'Multiple Choice',
                              onSelected: (sel) {
                                if (sel) {
                                  setState(() => _questionType = 'Multiple Choice');
                                }
                              },
                              selectedColor:
                                  const Color(0xFF7C3AED).withOpacity(0.18),
                              labelStyle: TextStyle(
                                color: _questionType == 'Multiple Choice'
                                    ? const Color(0xFF7C3AED)
                                    : subtitleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Descriptive / Text Answer'),
                              selected: _questionType == 'Descriptive',
                              onSelected: (sel) {
                                if (sel) {
                                  setState(() => _questionType = 'Descriptive');
                                }
                              },
                              selectedColor:
                                  const Color(0xFF7C3AED).withOpacity(0.18),
                              labelStyle: TextStyle(
                                color: _questionType == 'Descriptive'
                                    ? const Color(0xFF7C3AED)
                                    : subtitleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Question Image Upload
                        if (_questionImage != null &&
                            _questionImage!.isNotEmpty) ...[
                          Stack(
                            children: [
                              Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: AppImageView(
                                  imageSource: _questionImage,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        setState(() => _questionImage = null),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          OutlinedButton.icon(
                            onPressed: _pickQuestionImage,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 18,
                            ),
                            label: const Text(
                              'Upload Question Image (e.g. describe image / diagram)',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7C3AED),
                              side: BorderSide(
                                color: const Color(0xFF7C3AED).withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Question Text Label & Input
                        Text(
                          'Question Text *',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _questionController,
                          maxLines: 3,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                'Type your question clearly here...',
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.white38
                                  : Colors.grey[400],
                              fontSize: 13.5,
                            ),
                            contentPadding: const EdgeInsets.all(14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF7C3AED),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Question Marks
                        Row(
                          children: [
                            Text(
                              'Marks for this question *',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 80,
                              height: 38,
                              child: TextFormField(
                                controller: _marksController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  suffixText: 'pt',
                                  contentPadding: EdgeInsets.zero,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF7C3AED),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['1', '2', '4', '5', '10'].map((val) {
                            final isSel = _marksController.text.trim() == val;
                            return InkWell(
                              onTap: () {
                                setState(() => _marksController.text = val);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFF7C3AED).withOpacity(0.15)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSel
                                        ? const Color(0xFF7C3AED)
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$val pt${int.parse(val) > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSel
                                        ? const Color(0xFF7C3AED)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Answer Options Section
                        if (_questionType == 'Descriptive') ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF7C3AED).withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.edit_note_rounded,
                                  color: Color(0xFF7C3AED),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Descriptive Answer Mode',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Students will answer this question using an adaptive multi-line textfield (e.g. describing the uploaded image, explaining steps, or writing short answers). No multiple choice options are required.',
                                        style: TextStyle(
                                          color: subtitleColor,
                                          fontSize: 12.5,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Answer Options Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Answer Options & Correct Key',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tap letter to set correct',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Options List
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _optionControllers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final isCorrect = _selectedCorrectOption == idx;
                              final optionLetter =
                                  String.fromCharCode(65 + idx);

                              return QuestionOptionTile(
                                index: idx,
                                optionLetter: optionLetter,
                                controller: _optionControllers[idx],
                                isCorrect: isCorrect,
                                imageUrl: idx < _optionImages.length
                                    ? _optionImages[idx]
                                    : null,
                                canRemove: _optionControllers.length > 2,
                                isDarkMode: isDarkMode,
                                containerColor: containerColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                borderColor: borderColor,
                                onTapCorrect: () {
                                  setState(() => _selectedCorrectOption = idx);
                                },
                                onPickImage: () => _pickOptionImage(idx),
                                onRemoveImage: () {
                                  setState(() {
                                    _optionImages[idx] = null;
                                  });
                                },
                                onRemoveOption: () => _handleRemoveOption(idx),
                              );
                            },
                          ),
                          const SizedBox(height: 10),

                          // Add Option Button
                          if (_optionControllers.length < 6)
                            TextButton.icon(
                              onPressed: _handleAddOption,
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFF7C3AED),
                                size: 18,
                              ),
                              label: const Text(
                                'Add Another Option',
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],

                        const SizedBox(height: 16),
                        Divider(color: borderColor, height: 1),
                        const SizedBox(height: 16),

                        // Form Actions: Save or Save & Add Another
                        Row(
                          children: [
                            if (!widget.isForQuestionBank &&
                                _editingIndex == null) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _handleSaveQuestion(
                                            andAddAnother: true,
                                          ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: BorderSide(color: borderColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    '+ Save & Add Next',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _handleSaveQuestion(
                                          andAddAnother: false,
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _editingIndex != null
                                            ? 'Update Question'
                                            : 'Save Question',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !widget.isForQuestionBank
          ? Container(
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
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '← Back',
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
                        onPressed: _isLoading ? null : _handleProceedToReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Review & Publish (${_currentExam.questions.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
