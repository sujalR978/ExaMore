import 'package:flutter/material.dart';
import 'package:prep_mate/features/User/screen/examResultScreen.dart';

class ActiveExamScreen extends StatefulWidget {
  const ActiveExamScreen({super.key});

  @override
  State<ActiveExamScreen> createState() => _ActiveExamScreenState();
}

class _ActiveExamScreenState extends State<ActiveExamScreen> {
  int? _selectedOption = 0; // Default selecting option A (index 0)

  void _handleOptionSelect(int index) {
    setState(() {
      _selectedOption = index;
    });
  }

  void _handlePrevious() {
    print('Previous clicked');
  }

  void _handleNext() {
    print('Next Question clicked');
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
                  color: isDarkMode
                      ? const Color(0xFF94A3B8)
                      : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const ExamResultScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24), // Amber CTA
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
      // Capsule-shaped Top Bar matching your app design
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
                    onPressed: () => Navigator.pop(context),
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
                          color: isDarkMode
                              ? const Color(0xFF312E81)
                              : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '45:22',
                              style: TextStyle(
                                color: isDarkMode
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF1D4ED8),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Progress Header & Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'QUESTION 15 OF 50',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '30% Completed',
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
                value: 0.30,
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
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject Tag
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
                      'Calculus',
                      style: TextStyle(
                        color: isDarkMode
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFF1D4ED8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Question Title
                  Text(
                    'What is the derivative of sin(x) with respect to x?',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Option A
                  _buildOptionItem(
                    0,
                    'A',
                    'cos(x)',
                    isDarkMode,
                    containerColor,
                    textColor,
                    borderColor,
                  ),
                  const SizedBox(height: 12),
                  // Option B
                  _buildOptionItem(
                    1,
                    'B',
                    '-cos(x)',
                    isDarkMode,
                    containerColor,
                    textColor,
                    borderColor,
                  ),
                  const SizedBox(height: 12),
                  // Option C
                  _buildOptionItem(
                    2,
                    'C',
                    'tan(x)',
                    isDarkMode,
                    containerColor,
                    textColor,
                    borderColor,
                  ),
                  const SizedBox(height: 12),
                  // Option D
                  _buildOptionItem(
                    3,
                    'D',
                    'sec(x)',
                    isDarkMode,
                    containerColor,
                    textColor,
                    borderColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Buttons Row (Previous & Next Question)
            Row(
              children: [
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
                        Icon(Icons.arrow_back, size: 18, color: textColor),
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
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? const Color(0xFF312E81)
                          : const Color(0xFF1E1B4B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next Question',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
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
                  backgroundColor: const Color(0xFFFBBF24), // Amber CTA style
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

  Widget _buildOptionItem(
    int index,
    String label,
    String text,
    bool isDarkMode,
    Color containerColor,
    Color textColor,
    Color borderColor,
  ) {
    final isSelected = _selectedOption == index;

    return GestureDetector(
      onTap: () => _handleOptionSelect(index),
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
                      : subtitleColor(isDarkMode),
                  width: 1.5,
                ),
                color: isSelected
                    ? (isDarkMode
                          ? const Color(0xFF312E81)
                          : const Color(0xFF1E1B4B))
                    : Colors.transparent,
              ),
              child: Center(
                child: isSelected && index == 0
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : subtitleColor(isDarkMode),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color subtitleColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFF94A3B8) : Colors.grey.shade600;
  }
}
