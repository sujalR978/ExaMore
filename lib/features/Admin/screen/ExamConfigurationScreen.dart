import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/screen/AddMultipleChoiceQuestionScreen.dart';

class ExamConfigurationScreen extends StatefulWidget {
  const ExamConfigurationScreen({super.key});

  @override
  State<ExamConfigurationScreen> createState() =>
      _ExamConfigurationScreenState();
}

class _ExamConfigurationScreenState extends State<ExamConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(
    text: '120',
  );
  final TextEditingController _marksController = TextEditingController(
    text: '100',
  );
  final TextEditingController _negativeMarkingController =
      TextEditingController(text: '0.25');

  String? _selectedCategory;
  final List<String> _categories = [
    'Mathematics',
    'Science',
    'History',
    'Computer Science',
  ];

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddMultipleChoiceQuestionScreen(),
        ),
      );
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
                    icon: Icon(Icons.menu, color: textColor),
                    onPressed: () {
                      print('Menu clicked');
                    },
                  ),
                  title: Text(
                    'Exam Administration',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: Icon(Icons.person_outline, color: textColor),
                        onPressed: () {
                          print('Profile clicked');
                        },
                      ),
                    ),
                  ],
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
                      'Exam Configuration',
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
                      validator: (val) => val == null || val.isEmpty
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
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please enter duration'
                          : null,
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

                    // Bottom Action Buttons (Cancel & Next)
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
                              onPressed: _handleNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFFBBF24,
                                ), // Amber CTA button
                                foregroundColor: const Color(0xFF1E1B4B),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                ? (isDarkMode
                      ? const Color(0xFF1E1B4B)
                      : const Color(0xFF1E1B4B))
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
