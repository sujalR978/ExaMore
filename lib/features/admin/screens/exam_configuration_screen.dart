// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/models/classroom_model.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/screens/add_multiple_choice_question_screen.dart';
import 'package:prep_mate/features/admin/services/classroom_service.dart';
import 'package:prep_mate/features/admin/widgets/admin_menu_drawer.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';

class ExamConfigurationScreen extends StatefulWidget {
  final ExamModel? exam; // Pass null to create new, or pass existing exam to edit
  final ClassroomModel? classroom; // Optional classroom context

  const ExamConfigurationScreen({super.key, this.exam, this.classroom});

  @override
  State<ExamConfigurationScreen> createState() =>
      _ExamConfigurationScreenState();
}

class _ExamConfigurationScreenState extends State<ExamConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ExamService _examService = ExamService();

  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _marksController;
  late TextEditingController _negativeMarkingController;

  ClassroomModel? _selectedClassroom;
  List<ClassroomModel> _availableClassrooms = [];
  String _selectedCategory = 'General';
  List<String> _categoryOptions = ['General'];
  bool _isLoading = false;

  bool get _isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.exam?.title ?? '');
    _durationController = TextEditingController(
      text: widget.exam != null
          ? widget.exam!.durationMinutes.toString()
          : '120',
    );
    _marksController = TextEditingController(
      text: widget.exam != null
          ? widget.exam!.totalMarks.toInt().toString()
          : '100',
    );
    _negativeMarkingController = TextEditingController(
      text: widget.exam != null
          ? widget.exam!.negativeMarking.toString()
          : '0.25',
    );

    _selectedClassroom = widget.classroom;
    if (widget.exam?.category != null && widget.exam!.category.isNotEmpty) {
      _selectedCategory = widget.exam!.category;
    }

    _recomputeCategoryOptions();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final classrooms =
          await ClassroomService.getClassroomsStream(currentUser.uid).first;
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

  void _showAddSubjectInlineDialog() {
    if (_selectedClassroom == null) return;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.library_books_outlined, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('Add Subject to Class'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a new subject to "${_selectedClassroom!.name}":',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Organic Chemistry, Calculus',
                border: OutlineInputBorder(),
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
            ),
            onPressed: () async {
              final newSubject = controller.text.trim();
              if (newSubject.isNotEmpty) {
                await ClassroomService.addSubject(
                  classroomId: _selectedClassroom!.id,
                  subjectName: newSubject,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {
                    if (!_selectedClassroom!.subjects.contains(newSubject)) {
                      _selectedClassroom!.subjects.add(newSubject);
                    }
                    _selectedCategory = newSubject;
                    _recomputeCategoryOptions();
                  });
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("You must be logged in to create or edit an exam.");
      }

      final title = _titleController.text.trim();
      final category = _selectedCategory;
      final duration = int.tryParse(_durationController.text.trim()) ?? 120;
      final totalMarks = double.tryParse(_marksController.text.trim()) ?? 100.0;
      final negativeMarking =
          double.tryParse(_negativeMarkingController.text.trim()) ?? 0.0;

      // Ensure a valid adminId is assigned
      final String assignedAdminId = (widget.exam?.adminId.isNotEmpty ?? false)
          ? widget.exam!.adminId
          : currentUser.uid;

      ExamModel currentExam;

      if (_isEditing) {
        currentExam = widget.exam!.copyWith(
          title: title,
          category: category,
          adminId: assignedAdminId,
          classroomId: _selectedClassroom?.id,
          classroomName: _selectedClassroom?.name,
          durationMinutes: duration,
          totalMarks: totalMarks,
          negativeMarking: negativeMarking,
          updatedAt: DateTime.now(),
        );
        await _examService.updateExam(currentExam);
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
          status: 'Draft',
        );

        final newDocId = await _examService.createExamDraft(
          currentExam,
          adminId: assignedAdminId,
        );
        currentExam = currentExam.copyWith(id: newDocId);
      }

      if (!mounted) return;

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      key: _scaffoldKey,
      drawer: const AdminMenuDrawer(),
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
                    _isEditing ? 'Edit Exam' : 'Configure Exam',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  _buildStepItem('1', 'Exam Details', true, true, isDarkMode),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: isDarkMode
                          ? const Color(0xFF0F766E)
                          : const Color(0xFF0D9488),
                    ),
                  ),
                  _buildStepItem(
                    '2',
                    'Add Questions',
                    false,
                    false,
                    isDarkMode,
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  _buildStepItem('3', 'Review', false, false, isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam Information',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure classroom, subject, marks, and duration for this test.',
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // 1. Exam Title
                    _buildFieldLabel('Exam Title *', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        hint: 'e.g., Midterm Biology 101, Linear Algebra Quiz',
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter exam title'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 2. Target Classroom Selector (Only when NOT created inside a specific class)
                    if (widget.classroom == null) ...[
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
                              'Global / All Classes (No specific class)',
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
                              _selectedClassroom =
                                  match.isNotEmpty ? match.first : null;
                            }
                            _recomputeCategoryOptions();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // When launched from inside a classroom, don't ask for selection.
                      // Show a neat auto-bound info badge.
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
                                color:
                                    const Color(0xFF7C3AED).withOpacity(0.12),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        (widget.classroom!.section.isNotEmpty
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
                                color:
                                    const Color(0xFF10B981).withOpacity(0.12),
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

                    // 3. Subject / Category: 1) General, 2) Class Subjects
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
                                fontSize: 11,
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
                        final isGeneral = category.toLowerCase() == 'general';
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
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.12),
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
                    const SizedBox(height: 16),

                    // 4. Duration
                    _buildFieldLabel('Duration (Minutes) *', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        hint: '120',
                        prefixIcon: Icon(
                          Icons.timer_outlined,
                          color: subtitleColor,
                          size: 20,
                        ),
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter duration';
                        }
                        if (int.tryParse(val.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 5. Total Marks
                    _buildFieldLabel('Total Marks', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _marksController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        hint: '100',
                        prefixIcon: Icon(
                          Icons.score_outlined,
                          color: subtitleColor,
                          size: 20,
                        ),
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (val) {
                        if (val != null &&
                            val.isNotEmpty &&
                            double.tryParse(val.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 6. Negative Marking
                    _buildFieldLabel(
                      'Negative Marking (Per Question)',
                      subtitleColor,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _negativeMarkingController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        hint: '0.25',
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
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _handleCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
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
                                      Icon(Icons.arrow_forward, size: 16),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
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
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildStepItem(
    String step,
    String title,
    bool isActive,
    bool isCompleted,
    bool isDarkMode,
  ) {
    Color bg = isCompleted
        ? const Color(0xFF0D9488)
        : (isActive ? const Color(0xFF7C3AED) : Colors.grey.shade400);

    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: bg,
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isActive
                ? (isDarkMode ? Colors.white : Colors.black87)
                : Colors.grey,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
