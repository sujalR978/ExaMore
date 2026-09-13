import 'package:flutter/material.dart';

class EditActiveExamScreen extends StatefulWidget {
  final String examTitle;
  final String examId;
  final String startDate;
  final String duration;
  final String enrolled;

  const EditActiveExamScreen({
    super.key,
    this.examTitle = 'Finals 2024 – Advanced Physics',
    this.examId = 'EXM-2024-089',
    this.startDate = 'Oct 24, 09:00 AM',
    this.duration = '120',
    this.enrolled = '145',
  });

  @override
  State<EditActiveExamScreen> createState() => _EditActiveExamScreenState();
}

class _EditActiveExamScreenState extends State<EditActiveExamScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _idController;
  late final TextEditingController _startDateController;
  late final TextEditingController _durationController;
  late final TextEditingController _enrolledController;

  bool _isPublished = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.examTitle);
    _idController = TextEditingController(text: widget.examId);
    _startDateController = TextEditingController(text: widget.startDate);
    _durationController = TextEditingController(text: widget.duration);
    _enrolledController = TextEditingController(text: widget.enrolled);
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

  void _handleSaveChanges() {
    if (_formKey.currentState!.validate()) {
      print('Saving updated exam parameters...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam updated successfully!')),
      );
      Navigator.pop(context);
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
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

      // Capsule-shaped Top Bar
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
                      validator: (val) => val == null || val.isEmpty
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
                      validator: (val) => val == null || val.isEmpty
                          ? 'Exam ID cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Start Date Field
                    _buildFieldLabel('Start Date & Time *', subtitleColor),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _startDateController,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Oct 24, 09:00 AM',
                        prefixIcon: Icon(
                          Icons.calendar_today_outlined,
                          color: subtitleColor,
                          size: 18,
                        ),
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (val) => val == null || val.isEmpty
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
                      validator: (val) => val == null || val.isEmpty
                          ? 'Duration cannot be empty'
                          : null,
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
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enrolled count cannot be empty'
                          : null,
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
                              onPressed: _handleCancel,
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
                              onPressed: _handleSaveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFFBBF24,
                                ), // Amber CTA style
                                foregroundColor: const Color(0xFF1E1B4B),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
