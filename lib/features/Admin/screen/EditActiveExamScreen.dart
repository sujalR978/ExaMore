import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';


class EditActiveExamScreen extends StatefulWidget {
  final ExamModel exam;

  const EditActiveExamScreen({super.key, required this.exam});

  @override
  State<EditActiveExamScreen> createState() => _EditActiveExamScreenState();
}

class _EditActiveExamScreenState extends State<EditActiveExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExamService _examService = ExamService();

  late final TextEditingController _titleController;
  late final TextEditingController _idController;
  late final TextEditingController _startDateController;
  late final TextEditingController _durationController;
  late final TextEditingController _enrolledController;

  late bool _isPublished;
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final exam = widget.exam;
    _selectedDateTime = exam.startDate ?? exam.createdAt;

    _titleController = TextEditingController(text: exam.title);
    _idController = TextEditingController(text: exam.examCode);
    _startDateController = TextEditingController(
      text: _formatDisplayDate(_selectedDateTime),
    );
    _durationController = TextEditingController(
      text: exam.durationMinutes.toString(),
    );
    _enrolledController = TextEditingController(
      text: exam.enrolledCount.toString(),
    );

    _isPublished = exam.status.toLowerCase() == 'published';
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final hour = hour12.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month $day, $hour:$minute $period';
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _selectedDateTime ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _startDateController.text = _formatDisplayDate(_selectedDateTime);
    });
  }

  Future<void> _handleSaveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedExam = widget.exam.copyWith(
        title: _titleController.text.trim(),
        examCode: _idController.text.trim(),
        durationMinutes: int.tryParse(_durationController.text.trim()) ?? 0,
        enrolledCount: int.tryParse(_enrolledController.text.trim()) ?? 0,
        status: _isPublished ? 'Published' : 'Draft',
        startDate: _selectedDateTime,
        updatedAt: DateTime.now(),
      );

      await _examService.updateExam(updatedExam);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update exam: $e'),
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
    _idController.dispose();
    _startDateController.dispose();
    _durationController.dispose();
    _enrolledController.dispose();
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
                    onPressed: _handleCancel,
                  ),
                  title: Text(
                    'Edit Active Exam',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Modify Exam Details',
              style: TextStyle(
                color: textColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Update configuration parameters, scheduling, and publication status.',
              style: TextStyle(color: subtitleColor, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Main Edit Card Container
            Container(
              padding: const EdgeInsets.all(22),
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
                    // Publication Status Toggle Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Publication Status',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isPublished
                                  ? 'Currently live for students'
                                  : 'Saved as draft',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isPublished,
                          onChanged: (val) {
                            setState(() {
                              _isPublished = val;
                            });
                          },
                          activeColor: const Color(0xFFFBBF24),
                          activeTrackColor: const Color(0xFF1E1B4B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 20),

                    // Exam Title Field
                    _buildFieldLabel('Exam Title *', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Enter exam title',
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Title cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Exam ID Field
                    _buildFieldLabel('Exam ID *', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _idController,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        hint: 'e.g., EXM-2024-089',
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Exam ID cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Start Date Field (with Date Picker)
                    _buildFieldLabel('Start Date & Time *', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: _pickDateTime,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Select start date & time',
                        prefixIcon: Icon(
                          Icons.calendar_today_outlined,
                          color: subtitleColor,
                          size: 18,
                        ),
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Start date cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Duration Field
                    _buildFieldLabel('Duration (Minutes) *', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        hint: '120',
                        prefixIcon: Icon(
                          Icons.access_time,
                          color: subtitleColor,
                          size: 18,
                        ),
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Duration cannot be empty';
                        }
                        if (int.tryParse(val.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Enrolled Students Field
                    _buildFieldLabel('Enrolled Capacity *', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _enrolledController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        hint: '145',
                        prefixIcon: Icon(
                          Icons.people_outline,
                          color: subtitleColor,
                          size: 18,
                        ),
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enrolled count cannot be empty';
                        }
                        if (int.tryParse(val.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 20),

                    // Bottom Buttons Row (Cancel & Save Changes)
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
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSaveChanges,
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
                                        Icon(Icons.save_outlined, size: 18),
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

  Widget _buildFieldLabel(String label, Color subtitleColor) {
    return Text(
      label,
      style: TextStyle(
        color: subtitleColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
      prefixIcon: prefixIcon,
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
