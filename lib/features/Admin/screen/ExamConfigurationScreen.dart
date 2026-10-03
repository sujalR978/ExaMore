import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/screen/AddMultipleChoiceQuestionScreen.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';


class ExamConfigurationScreen extends StatefulWidget {
  final ExamModel?
  exam; // Pass null to create new, or pass existing exam to edit

  const ExamConfigurationScreen({super.key, this.exam});

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

  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Mathematics',
    'Science',
    'History',
    'Computer Science',
  ];

  bool get _isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    // Pre-populate if editing an existing exam
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

    if (widget.exam != null && _categories.contains(widget.exam!.category)) {
      _selectedCategory = widget.exam!.category;
    } else if (widget.exam != null && widget.exam!.category.isNotEmpty) {
      _categories.add(widget.exam!.category);
      _selectedCategory = widget.exam!.category;
    }
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final category = _selectedCategory ?? 'General';
      final duration = int.tryParse(_durationController.text.trim()) ?? 120;
      final totalMarks = double.tryParse(_marksController.text.trim()) ?? 100.0;
      final negativeMarking =
          double.tryParse(_negativeMarkingController.text.trim()) ?? 0.0;

      ExamModel currentExam;

      if (_isEditing) {
        currentExam = widget.exam!.copyWith(
          title: title,
          category: category,
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
          durationMinutes: duration,
          totalMarks: totalMarks,
          negativeMarking: negativeMarking,
          status: 'Draft',
        );
        final newDocId = await _examService.createExamDraft(currentExam);
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
                    icon: Icon(Icons.menu, color: textColor),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  title: Text(
                    _isEditing ? 'Edit Exam' : 'Exam Administration',
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
            // Stepper Header Indicator
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  // Step 1 (Active)
                  _buildStepItem('1', 'Exam Details', true, true, isDarkMode),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: isDarkMode
                          ? const Color(0xFF0F766E)
                          : const Color(0xFF0D9488),
                    ),
                  ),
                  // Step 2 (Inactive)
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
                      color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  // Step 3 (Inactive)
                  _buildStepItem(
                    '3',
                    'Review & Publish',
                    false,
                    false,
                    isDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Configuration Card
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Configuration' : 'Exam Configuration',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 20),

                    // Exam Title Field
                    _buildFieldLabel('Exam Title *', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        hint: 'e.g., Midterm Biology 101',
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter exam title'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    _buildFieldLabel('Category', subtitleColor),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: containerColor,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'Select Category',
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Duration Field
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

                    // Total Marks Field
                    _buildFieldLabel('Total Marks', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _marksController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        hint: '100',
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

                    // Negative Marking Field
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
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pro Tip Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pro Tip',
                                  style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Setting a negative marking value encourages students to be more careful with their answers. Leave at 0 if no penalty applies.',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 20),

                    // Bottom Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: BorderSide(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFBBF24),
                                foregroundColor: const Color(0xFF1E1B4B),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF1E1B4B),
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Next: Add Questions',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(Icons.arrow_forward, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStepItem(
    String number,
    String label,
    bool isActive,
    bool isCompleted,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1E1B4B)
                : (isDarkMode
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFFFBBF24)
                    : (isDarkMode ? Colors.white60 : Colors.grey.shade600),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? (isDarkMode ? Colors.white : const Color(0xFF1E1B4B))
                : (isDarkMode ? const Color(0xFF94A3B8) : Colors.grey.shade600),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, Color subtitleColor) {
    return Text(
      label,
      style: TextStyle(
        color: subtitleColor,
        fontSize: 13,
        fontWeight: FontWeight.bold,
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
      hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
      prefixIcon: prefixIcon,
      suffixText: suffixText,
      suffixStyle: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: isDarkMode
          ? const Color(0xFF1E293B).withOpacity(0.5)
          : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
