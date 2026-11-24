// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prep_mate/core/services/notification_service.dart';
import 'package:prep_mate/features/admin/models/classroom_model.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/screens/add_multiple_choice_question_screen.dart';
import 'package:prep_mate/features/admin/services/classroom_service.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/admin/widgets/admin_top_bar.dart';
import 'package:prep_mate/features/admin/widgets/exam_stepper_header.dart';

class ExamConfigurationScreen extends StatefulWidget {
  final ExamModel?
  exam; // Pass null to create new, or pass existing exam to edit
  final ClassroomModel? classroom; // Optional classroom context

  const ExamConfigurationScreen({super.key, this.exam, this.classroom});

  @override
  State<ExamConfigurationScreen> createState() =>
      _ExamConfigurationScreenState();
}

class _ExamConfigurationScreenState extends State<ExamConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExamService _examService = ExamService();

  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _marksController;
  late TextEditingController _negativeMarkingController;
  late TextEditingController _passingScoreController;
  late TextEditingController _allowedAttemptsController;

  bool _shuffleQuestions = false;
  bool _showResultsImmediately = false;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _publishRightNow = false;

  ClassroomModel? _selectedClassroom;
  List<ClassroomModel> _availableClassrooms = [];
  String _selectedCategory = 'General';
  List<String> _categoryOptions = ['General'];
  bool _isLoading = false;
  ExamModel? _latestExam;

  bool get _isEditing => widget.exam != null;
  bool get _isLockedToClassroom => widget.classroom != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.exam?.title ?? '');
    _durationController = TextEditingController(
      text: widget.exam != null
          ? widget.exam!.durationMinutes.toString()
          : '60',
    );
    _marksController = TextEditingController(
      text: widget.exam != null
          ? widget.exam!.totalMarks.toInt().toString()
          : '50',
    );
    _negativeMarkingController = TextEditingController(
      text: widget.exam != null
          ? widget.exam!.negativeMarking.toString()
          : '0.0',
    );
    _passingScoreController = TextEditingController(
      text: widget.exam != null
          ? widget.exam!.passingScorePercentage.toInt().toString()
          : '50',
    );
    _allowedAttemptsController = TextEditingController(
      text: widget.exam != null ? widget.exam!.allowedAttempts.toString() : '1',
    );

    _shuffleQuestions = widget.exam?.shuffleQuestions ?? false;
    _showResultsImmediately = widget.exam?.showResultsImmediately ?? false;
    _startDate = widget.exam?.startDate;
    _endDate = widget.exam?.endDate;

    _selectedClassroom = widget.classroom;
    if (widget.exam?.category != null && widget.exam!.category.isNotEmpty) {
      _selectedCategory = widget.exam!.category;
    }

    _latestExam = widget.exam;
    _recomputeCategoryOptions();
    _loadClassrooms();
    if (_isEditing && widget.exam!.id.isNotEmpty) {
      _loadFreshExamData();
    }
  }

  Future<void> _loadFreshExamData() async {
    if (widget.exam == null || widget.exam!.id.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('exams')
          .doc(widget.exam!.id)
          .get();
      if (doc.exists && doc.data() != null && mounted) {
        final fresh = ExamModel.fromFirestore(doc);
        setState(() {
          _latestExam = fresh;
        });
      }
    } catch (e) {
      debugPrint('Error loading fresh exam in config: $e');
    }
  }

  Future<void> _loadClassrooms() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final classrooms = await ClassroomService.getClassroomsStream(
        currentUser.uid,
      ).first;
      if (mounted) {
        setState(() {
          _availableClassrooms = classrooms;

          // If no classroom was passed in directly, match from existing exam
          if (_selectedClassroom == null && widget.exam?.classroomId != null) {
            final match = _availableClassrooms.where(
              (c) => c.id == widget.exam!.classroomId,
            );
            if (match.isNotEmpty) {
              _selectedClassroom = match.first;
            }
          } else if (_selectedClassroom != null) {
            final match = _availableClassrooms.where(
              (c) => c.id == _selectedClassroom!.id,
            );
            if (match.isNotEmpty) {
              _selectedClassroom = match.first;
            }
          }
          _recomputeCategoryOptions();
        });
      }
    } catch (_) {}
  }

  void _recomputeCategoryOptions() {
    // 1) "General" is always the top option
    final List<String> options = ['General'];

    // 2) Below "General", list all subjects belonging to that class
    if (_selectedClassroom != null) {
      for (final s in _selectedClassroom!.subjects) {
        final clean = s.trim();
        if (clean.isNotEmpty &&
            !options.any((o) => o.toLowerCase() == clean.toLowerCase())) {
          options.add(clean);
        }
      }
    } else {
      // Global fallback subjects if no specific classroom is chosen
      for (final s in [
        'Mathematics',
        'Science',
        'History',
        'Computer Science',
      ]) {
        if (!options.contains(s)) options.add(s);
      }
    }

    // Preserve existing category when editing
    if (widget.exam != null && widget.exam!.category.isNotEmpty) {
      if (!options.any(
        (o) => o.toLowerCase() == widget.exam!.category.toLowerCase(),
      )) {
        options.add(widget.exam!.category);
      }
    }

    setState(() {
      _categoryOptions = options;
      if (!_categoryOptions.contains(_selectedCategory)) {
        _selectedCategory = _categoryOptions.first; // Default to 'General'
      }
    });
  }

  Future<void> _showAddSubjectInlineDialog() async {
    if (_selectedClassroom == null) return;

    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.book_outlined,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Add New Subject',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add subject(s) to "${_selectedClassroom!.name}". Separate multiple subjects with commas for instant batch adding:',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Physics, Economics, English',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
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
              final raw = controller.text.trim();
              if (raw.isNotEmpty) {
                final names = raw
                    .split(RegExp(r'[,;\n]+'))
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                if (names.isNotEmpty) {
                  // Instant 0ms optimistic update
                  setState(() {
                    for (final n in names) {
                      if (!_selectedClassroom!.subjects.contains(n)) {
                        _selectedClassroom!.subjects.add(n);
                      }
                    }
                    _selectedCategory = names.first;
                    _recomputeCategoryOptions();
                  });
                  Navigator.pop(ctx);

                  // Asynchronous batch Firestore sync
                  ClassroomService.addSubjects(
                    classroomId: _selectedClassroom!.id,
                    subjectNames: names,
                  );
                }
              }
            },
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext() async {
    await _saveConfiguration(proceedToQuestions: true);
  }

  Future<void> _saveOnlyConfiguration() async {
    await _saveConfiguration(proceedToQuestions: false);
  }

  Future<void> _saveConfiguration({required bool proceedToQuestions}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("You must be logged in to create or edit an exam.");
      }

      final title = _titleController.text.trim();
      final category = _selectedCategory;
      final duration = int.tryParse(_durationController.text.trim()) ?? 60;
      final totalMarks = double.tryParse(_marksController.text.trim()) ?? 50.0;
      final negativeMarking =
          double.tryParse(_negativeMarkingController.text.trim()) ?? 0.0;
      final passingPercentage =
          double.tryParse(_passingScoreController.text.trim()) ?? 50.0;
      final allowedAttempts =
          int.tryParse(_allowedAttemptsController.text.trim()) ?? 1;

      // Ensure valid adminId is assigned
      final String assignedAdminId = (widget.exam?.adminId.isNotEmpty ?? false)
          ? widget.exam!.adminId
          : currentUser.uid;

      final now = DateTime.now();
      final effectiveStart = _publishRightNow ? now : _startDate;

      // Validation 2: Publish time must be in future (after current date & time) or select "Publish Right Now"
      if (!_publishRightNow && _startDate != null) {
        if (_startDate!.isBefore(now.subtract(const Duration(minutes: 1)))) {
          if (mounted) setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Publish time must be after the current date and time (future only), or select "Publish Right Now".',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      // Validation 3 & 4: Close time must be in future of publish time and fulfill minimum exam duration
      if (_endDate != null) {
        final referenceStart = effectiveStart ?? now;

        // Validation 4: Close time must be in future of publish time
        if (!_endDate!.isAfter(referenceStart)) {
          if (mounted) setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.event_busy_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Close / Deadline time must be in the future of the Publish time.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // Validation 3: Close time must fulfill minimum exam duration
        final minCloseTime = referenceStart.add(Duration(minutes: duration));
        if (_endDate!.isBefore(minCloseTime)) {
          if (mounted) setState(() => _isLoading = false);
          final formattedMinClose = DateFormat('MMM dd, yyyy • hh:mm a').format(minCloseTime);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.timer_off_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Close time must fulfill the exam duration ($duration mins). Minimum allowed close time is $formattedMinClose.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      ExamModel currentExam;

      if (_isEditing) {
        final baseExam = _latestExam ?? widget.exam!;
        final oldStart = baseExam.startDate;
        final oldEnd = baseExam.endDate;
        final newStart = _publishRightNow ? now : _startDate;
        final newEnd = _endDate;

        currentExam = baseExam.copyWith(
          title: title,
          category: category,
          adminId: assignedAdminId,
          classroomId: _selectedClassroom?.id,
          classroomName: _selectedClassroom?.name,
          durationMinutes: duration,
          totalMarks: totalMarks,
          negativeMarking: negativeMarking,
          passingScorePercentage: passingPercentage,
          allowedAttempts: allowedAttempts,
          startDate: newStart,
          endDate: newEnd,
          shuffleQuestions: _shuffleQuestions,
          showResultsImmediately: _showResultsImmediately,
          updatedAt: DateTime.now(),
        );
        await _examService.updateExam(currentExam);

        // Detect if exam schedule or deadline timing was updated
        final bool isStartChanged = (oldStart == null && newStart != null) ||
            (oldStart != null && newStart == null) ||
            (oldStart != null && newStart != null && !oldStart.isAtSameMomentAs(newStart));
        final bool isEndChanged = (oldEnd == null && newEnd != null) ||
            (oldEnd != null && newEnd == null) ||
            (oldEnd != null && newEnd != null && !oldEnd.isAtSameMomentAs(newEnd));

        if (isStartChanged || isEndChanged) {
          try {
            await NotificationService.instance.sendTimingUpdatedNotification(
              exam: currentExam,
              oldStartDate: oldStart,
              newStartDate: newStart,
              oldEndDate: oldEnd,
              newEndDate: newEnd,
            );
          } catch (e) {
            debugPrint('Failed to send timing updated notification: $e');
          }
        }
      } else {
        currentExam = ExamModel(
          id: '',
          examCode: '',
          title: title,
          category: category,
          adminId: assignedAdminId,
          classroomId: _selectedClassroom?.id,
          classroomName: _selectedClassroom?.name,
          durationMinutes: duration,
          totalMarks: totalMarks,
          negativeMarking: negativeMarking,
          passingScorePercentage: passingPercentage,
          allowedAttempts: allowedAttempts,
          startDate: _publishRightNow ? now : _startDate,
          endDate: _endDate,
          shuffleQuestions: _shuffleQuestions,
          showResultsImmediately: _showResultsImmediately,
          status: 'Draft',
        );

        final newDocId = await _examService.createExamDraft(
          currentExam,
          adminId: assignedAdminId,
        );
        currentExam = currentExam.copyWith(id: newDocId);
      }

      if (!mounted) return;

      if (!proceedToQuestions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Exam configuration saved successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              AddMultipleChoiceQuestionScreen(exam: currentExam),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save configuration: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _marksController.dispose();
    _negativeMarkingController.dispose();
    _passingScoreController.dispose();
    _allowedAttemptsController.dispose();
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
        : const Color(0xFF64748B);
    final borderColor = isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AdminTopBar(
        title: _isEditing ? 'Edit Exam' : 'Create New Exam',
        subtitle: 'Step 1 of 3 • Basic Configuration',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        actions: [
          if (_isLockedToClassroom)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.school,
                        size: 14,
                        color: Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.classroom!.name,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          ExamStepperHeader(
            currentStep: 1,
            onStepTapped: _isEditing
                ? (step) {
                    if (step == 2) {
                      _handleNext();
                    }
                  }
                : null,
          ),
          if (_isEditing)
            InkWell(
              onTap: _handleNext,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.quiz_outlined,
                      size: 18,
                      color: Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This exam has ${(_latestExam ?? widget.exam)!.questions.length} questions attached.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    const Text(
                      'Manage Questions →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARD 1: GENERAL INFORMATION
                    _buildSectionCard(
                      title: 'General Information',
                      subtitle:
                          'Define the exam title, classroom, and primary subject.',
                      icon: Icons.description_outlined,
                      containerColor: containerColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      children: [
                        // Exam Title
                        _buildFieldLabel('Exam Title *', subtitleColor),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleController,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: 'e.g. Unit 3 Midterm, Linear Algebra Quiz',
                            prefixIcon: Icon(
                              Icons.edit_note_rounded,
                              color: subtitleColor,
                              size: 20,
                            ),
                            subtitleColor: subtitleColor,
                            borderColor: borderColor,
                            isDarkMode: isDarkMode,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Please enter an exam title'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Target Classroom Selector
                        if (!_isLockedToClassroom) ...[
                          _buildFieldLabel(
                            'Target Classroom (Optional)',
                            subtitleColor,
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String?>(
                            isExpanded: true,
                            value: _selectedClassroom?.id,
                            dropdownColor: containerColor,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: _inputDecoration(
                              hint: 'Select Classroom (Optional)',
                              prefixIcon: Icon(
                                Icons.school_outlined,
                                color: subtitleColor,
                                size: 20,
                              ),
                              subtitleColor: subtitleColor,
                              borderColor: borderColor,
                              isDarkMode: isDarkMode,
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Global / All Classes (Open Access)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              ..._availableClassrooms.map((c) {
                                return DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.class_outlined,
                                        size: 16,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          c.name +
                                              (c.section.isNotEmpty
                                                  ? ' (${c.section})'
                                                  : ''),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                if (val == null) {
                                  _selectedClassroom = null;
                                } else {
                                  final match = _availableClassrooms.where(
                                    (c) => c.id == val,
                                  );
                                  _selectedClassroom = match.isNotEmpty
                                      ? match.first
                                      : null;
                                }
                                _recomputeCategoryOptions();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          // Clean read-only banner when launched inside a classroom
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF7C3AED,
                                    ).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.school,
                                    size: 18,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Classroom',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtitleColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        widget.classroom!.name +
                                            (widget
                                                    .classroom!
                                                    .section
                                                    .isNotEmpty
                                                ? ' (${widget.classroom!.section})'
                                                : ''),
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 12,
                                        color: Color(0xFF10B981),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Selected',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Subject / Category Selector
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedClassroom != null
                                    ? 'Subject for "${_selectedClassroom!.name}" *'
                                    : 'Subject / Category *',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selectedClassroom != null)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF7C3AED),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                                onPressed: _showAddSubjectInlineDialog,
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text(
                                  'Add Subject',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _categoryOptions.contains(_selectedCategory)
                              ? _selectedCategory
                              : _categoryOptions.first,
                          dropdownColor: containerColor,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: 'Select Subject',
                            prefixIcon: Icon(
                              Icons.library_books_outlined,
                              color: subtitleColor,
                              size: 20,
                            ),
                            subtitleColor: subtitleColor,
                            borderColor: borderColor,
                            isDarkMode: isDarkMode,
                          ),
                          items: _categoryOptions.map((category) {
                            final isGeneral =
                                category.toLowerCase() == 'general';
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    isGeneral
                                        ? Icons.public
                                        : Icons.menu_book_rounded,
                                    size: 16,
                                    color: isGeneral
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF7C3AED),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: isGeneral
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (isGeneral) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Default',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CARD 2: TIMING & SCORING
                    _buildSectionCard(
                      title: 'Timing & Scoring',
                      subtitle:
                          'Set duration limit, total points, and penalty for wrong answers.',
                      icon: Icons.timer_outlined,
                      containerColor: containerColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      children: [
                        // Duration
                        _buildFieldLabel(
                          'Exam Duration (Minutes) *',
                          subtitleColor,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: '60',
                            suffixText: 'mins',
                            prefixIcon: Icon(
                              Icons.access_time_rounded,
                              color: subtitleColor,
                              size: 20,
                            ),
                            subtitleColor: subtitleColor,
                            borderColor: borderColor,
                            isDarkMode: isDarkMode,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter duration in minutes';
                            }
                            final n = int.tryParse(val.trim());
                            if (n == null || n <= 0) {
                              return 'Enter a valid positive number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildQuickChip('30m', '30', _durationController),
                            _buildQuickChip('45m', '45', _durationController),
                            _buildQuickChip('60m', '60', _durationController),
                            _buildQuickChip('90m', '90', _durationController),
                            _buildQuickChip('120m', '120', _durationController),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Total Marks
                        _buildFieldLabel('Total Exam Marks *', subtitleColor),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _marksController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: '50',
                            suffixText: 'pts',
                            prefixIcon: Icon(
                              Icons.functions_rounded,
                              color: subtitleColor,
                              size: 20,
                            ),
                            subtitleColor: subtitleColor,
                            borderColor: borderColor,
                            isDarkMode: isDarkMode,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter total marks';
                            }
                            final n = double.tryParse(val.trim());
                            if (n == null || n <= 0) {
                              return 'Enter a valid positive score';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildQuickChip('25 pts', '25', _marksController),
                            _buildQuickChip('50 pts', '50', _marksController),
                            _buildQuickChip('100 pts', '100', _marksController),
                            _buildQuickChip('200 pts', '200', _marksController),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Negative Marking
                        _buildFieldLabel(
                          'Negative Marking (per incorrect response)',
                          subtitleColor,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _negativeMarkingController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: '0.0',
                            suffixText: 'pts',
                            prefixIcon: Icon(
                              Icons.remove_circle_outline,
                              color: subtitleColor,
                              size: 20,
                            ),
                            subtitleColor: subtitleColor,
                            borderColor: borderColor,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildQuickChip(
                              'None (0.0)',
                              '0.0',
                              _negativeMarkingController,
                            ),
                            _buildQuickChip(
                              '-0.25',
                              '0.25',
                              _negativeMarkingController,
                            ),
                            _buildQuickChip(
                              '-0.33',
                              '0.33',
                              _negativeMarkingController,
                            ),
                            _buildQuickChip(
                              '-0.50',
                              '0.50',
                              _negativeMarkingController,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CARD 3: EVALUATION & EXAM RULES
                    _buildSectionCard(
                      title: 'Evaluation & Rules',
                      subtitle:
                          'Configure passing percentage, anti-cheat shuffling, and score visibility.',
                      icon: Icons.shield_outlined,
                      containerColor: containerColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      children: [
                        // Passing Score Percentage
                        _buildFieldLabel(
                          'Passing Score Percentage *',
                          subtitleColor,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passingScoreController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: '50',
                            suffixText: '%',
                            prefixIcon: Icon(
                              Icons.percent_rounded,
                              color: subtitleColor,
                              size: 20,
                            ),
                            subtitleColor: subtitleColor,
                            borderColor: borderColor,
                            isDarkMode: isDarkMode,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter passing score %';
                            }
                            final n = double.tryParse(val.trim());
                            if (n == null || n < 0 || n > 100) {
                              return 'Must be between 0 and 100';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildQuickChip(
                              '40%',
                              '40',
                              _passingScoreController,
                            ),
                            _buildQuickChip(
                              '50%',
                              '50',
                              _passingScoreController,
                            ),
                            _buildQuickChip(
                              '60%',
                              '60',
                              _passingScoreController,
                            ),
                            _buildQuickChip(
                              '75%',
                              '75',
                              _passingScoreController,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Allowed Attempts
                        _buildFieldLabel('Allowed Attempts *', subtitleColor),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _allowedAttemptsController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: '1',
                            suffixText: 'attempts',
                            prefixIcon: Icon(
                              Icons.replay_rounded,
                              color: subtitleColor,
                              size: 20,
                            ),
                            subtitleColor: subtitleColor,
                            borderColor: borderColor,
                            isDarkMode: isDarkMode,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter allowed attempts';
                            }
                            final n = int.tryParse(val.trim());
                            if (n == null || n <= 0) {
                              return 'Enter a valid positive number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildQuickChip(
                              '1 Attempt',
                              '1',
                              _allowedAttemptsController,
                            ),
                            _buildQuickChip(
                              '2 Attempts',
                              '2',
                              _allowedAttemptsController,
                            ),
                            _buildQuickChip(
                              '3 Attempts',
                              '3',
                              _allowedAttemptsController,
                            ),
                            _buildQuickChip(
                              '5 Attempts',
                              '5',
                              _allowedAttemptsController,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Timeslot Window (Open From & Closes At)
                        _buildFieldLabel(
                          'Exam Publishing & Closing Timeslot (Date & Time)',
                          subtitleColor,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Specify the exact date and time to publish (open) and close the exam. Students can only attempt within this active window.',
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                        ),
                        const SizedBox(height: 10),

                        _buildTimeslotTile(
                          title: 'Publish / Open Exam',
                          hintText:
                              'Immediate (available as soon as published)',
                          dateTime: _startDate,
                          icon: Icons.event_available_rounded,
                          isPublishTile: true,
                          onPickDate: () => _pickTimeslotDate(isStart: true),
                          onPickTime: () => _pickTimeslotTime(isStart: true),
                          onPickBoth: () =>
                              _pickTimeslotDateTime(isStart: true),
                          onClear: () => setState(() {
                            _startDate = null;
                            _publishRightNow = false;
                          }),
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          borderColor: borderColor,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 10),

                        _buildTimeslotTile(
                          title: 'Close / Deadline Exam',
                          hintText: 'No deadline (remains open indefinitely)',
                          dateTime: _endDate,
                          icon: Icons.event_busy_rounded,
                          onPickDate: () => _pickTimeslotDate(isStart: false),
                          onPickTime: () => _pickTimeslotTime(isStart: false),
                          onPickBoth: () =>
                              _pickTimeslotDateTime(isStart: false),
                          onClear: () => setState(() => _endDate = null),
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          borderColor: borderColor,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 20),

                        // Shuffle Questions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Shuffle Questions',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Randomizes question sequence for each student to prevent screen peeking.',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
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
                        Divider(color: borderColor, height: 24),

                        // Show Results Immediately
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Show Results Immediately',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Displays instant final score and review after student submits.',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
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
                  ],
                ),
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
                  onPressed: _handleCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_isEditing) ...[
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveOnlyConfiguration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
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
                              Icon(Icons.check_rounded, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleNext,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      foregroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Questions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
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
                                'Next: Questions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color containerColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
    required List<Widget> children,
  }) {
    return Material(
      color: containerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF7C3AED), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: subtitleColor, fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _pickTimeslotDate({required bool isStart}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final effectiveMin = isStart
        ? today
        : (_startDate != null
            ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
            : today);

    final current = isStart ? _startDate : _endDate;
    final initialDate = current ?? effectiveMin;
    final safeInitial = initialDate.isBefore(effectiveMin) ? effectiveMin : initialDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: effectiveMin,
      lastDate: now.add(const Duration(days: 730)),
    );

    if (pickedDate == null || !mounted) return;

    final existingTime = current != null
        ? TimeOfDay.fromDateTime(current)
        : (isStart
              ? const TimeOfDay(hour: 9, minute: 0)
              : const TimeOfDay(hour: 23, minute: 59));

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      existingTime.hour,
      existingTime.minute,
    );

    setState(() {
      if (isStart) {
        _publishRightNow = false;
        _startDate = combined;
        final duration = int.tryParse(_durationController.text.trim()) ?? 60;
        final minClose = _startDate!.add(Duration(minutes: duration));
        if (_endDate != null && _endDate!.isBefore(minClose)) {
          _endDate = minClose;
        }
      } else {
        _endDate = combined;
      }
    });
  }

  Future<void> _pickTimeslotTime({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final initialTime = current != null
        ? TimeOfDay.fromDateTime(current)
        : (isStart
              ? const TimeOfDay(hour: 9, minute: 0)
              : const TimeOfDay(hour: 23, minute: 59));

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null || !mounted) return;

    final now = DateTime.now();
    final baseDate =
        current ??
        (isStart ? now : (_startDate ?? now).add(const Duration(days: 1)));

    final combined = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validation 2: Publish time cannot be in the past
    if (isStart && combined.isBefore(now.subtract(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Publish time must be in the future (after current time), or select "Publish Right Now".',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      if (isStart) {
        _publishRightNow = false;
        _startDate = combined;
        final duration = int.tryParse(_durationController.text.trim()) ?? 60;
        final minClose = _startDate!.add(Duration(minutes: duration));
        if (_endDate != null && _endDate!.isBefore(minClose)) {
          _endDate = minClose;
        }
      } else {
        _endDate = combined;
      }
    });
  }

  Future<void> _pickTimeslotDateTime({required bool isStart}) async {
    await _pickTimeslotDate(isStart: isStart);
    if (!mounted) return;
    await _pickTimeslotTime(isStart: isStart);
  }

  Widget _buildTimeslotTile({
    required String title,
    required String hintText,
    required DateTime? dateTime,
    required VoidCallback onPickDate,
    required VoidCallback onPickTime,
    required VoidCallback onPickBoth,
    required VoidCallback onClear,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    required IconData icon,
    bool isPublishTile = false,
  }) {
    final bool isImmediatePublish = isPublishTile && _publishRightNow;
    final isSet = isImmediatePublish || dateTime != null;
    final dateStr = isImmediatePublish
        ? 'Today (Right Now)'
        : (dateTime != null
            ? DateFormat('EEE, MMM d, yyyy').format(dateTime)
            : 'Date: Not set');
    final timeStr = isImmediatePublish
        ? 'Immediate'
        : (dateTime != null
            ? DateFormat('h:mm a').format(dateTime)
            : 'Time: Not set');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSet ? const Color(0xFF7C3AED).withOpacity(0.5) : borderColor,
          width: isSet ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF7C3AED), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isImmediatePublish
                          ? '⚡ Publishing live immediately'
                          : (isSet ? 'Scheduled active' : hintText),
                      style: TextStyle(
                        color: isSet ? const Color(0xFF10B981) : subtitleColor,
                        fontSize: 11,
                        fontWeight: isSet ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              // Requirement 1: Quick toggle for "Publish Right Now"
              if (isPublishTile) ...[
                InkWell(
                  onTap: () {
                    setState(() {
                      _publishRightNow = !_publishRightNow;
                      if (_publishRightNow) {
                        _startDate = DateTime.now();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _publishRightNow
                          ? const Color(0xFF10B981)
                          : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _publishRightNow ? Icons.check_circle_rounded : Icons.bolt_rounded,
                          size: 14,
                          color: _publishRightNow ? Colors.white : subtitleColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Publish Right Now',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _publishRightNow ? Colors.white : textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (isSet)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: subtitleColor,
                  tooltip: 'Clear',
                  splashRadius: 18,
                  onPressed: onClear,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Date Button
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: onPickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSet
                            ? const Color(0xFF7C3AED).withOpacity(0.3)
                            : borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isImmediatePublish
                              ? Icons.bolt_rounded
                              : Icons.calendar_today_rounded,
                          size: 15,
                          color: isImmediatePublish
                              ? const Color(0xFF10B981)
                              : const Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSet ? textColor : subtitleColor,
                              fontSize: 12.5,
                              fontWeight: isSet
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Time Button
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: onPickTime,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSet
                            ? const Color(0xFF7C3AED).withOpacity(0.3)
                            : borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isImmediatePublish
                              ? Icons.check_circle_outline_rounded
                              : Icons.access_time_rounded,
                          size: 15,
                          color: isImmediatePublish
                              ? const Color(0xFF10B981)
                              : const Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            timeStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSet ? textColor : subtitleColor,
                              fontSize: 12.5,
                              fontWeight: isSet
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(
    String label,
    String value,
    TextEditingController controller,
  ) {
    final isSelected = controller.text.trim() == value;
    return InkWell(
      onTap: () {
        setState(() {
          controller.text = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED).withOpacity(0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 1.4 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF7C3AED) : Colors.grey,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    String? suffixText,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixText: suffixText,
      hintStyle: TextStyle(
        color: isDarkMode ? Colors.white38 : Colors.grey[400],
        fontSize: 13.5,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
