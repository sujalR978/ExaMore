import 'package:flutter/material.dart';

class ReviewAnswersScreen extends StatefulWidget {
  const ReviewAnswersScreen({super.key});

  @override
  State<ReviewAnswersScreen> createState() => _ReviewAnswersScreenState();
}

class _ReviewAnswersScreenState extends State<ReviewAnswersScreen> {
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
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Review Answers',
                    style: TextStyle(
                      color: textColor,
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
            // Top Summary Filter Cards (Incorrect & Skipped)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF451A03).withOpacity(0.4)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.red.withOpacity(0.3)
                            : Colors.red.shade100,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '5',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Incorrect',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '3',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Skipped',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question 1 Card: Incorrect Answer Example
            _buildReviewCard(
              questionNum: 'Question 4',
              subject: 'Chemistry',
              isCorrect: false,
              questionText: 'What is the chemical symbol for Gold?',
              hasYourAnswer: true,
              yourAnswerText: 'Ag',
              correctAnswerText: 'Au',
              explanationTitle: 'EXPLANATION',
              explanationText:
                  "'Au' comes from the Latin word 'aurum', which means shining dawn. 'Ag' is the symbol for Silver (argentum).",
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 20),

            // Question 2 Card: Skipped / Correct Example
            _buildReviewCard(
              questionNum: 'Question 12',
              subject: 'History',
              isCorrect: true, // or neutral
              questionText: 'In which year did the Berlin Wall fall?',
              hasYourAnswer: false,
              correctAnswerText: '1989',
              explanationTitle: 'EXPLANATION',
              explanationText:
                  'The Berlin Wall fell on November 9, 1989, marking a pivotal moment in the end of the Cold War and leading to German reunification.',
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 20),

            // Question 3 Card: Mathematical Derivative Example
            _buildReviewCard(
              questionNum: 'Question 15',
              subject: 'Mathematics',
              isCorrect: false,
              questionText: 'What is the derivative of $this.x^2?',
              hasYourAnswer: true,
              yourAnswerText: 'x',
              correctAnswerText: '2x',
              explanationTitle: 'SOLUTION HINT',
              explanationText:
                  'Use the power rule for derivatives: d/dx(x^n) = n*x^(n-1). Here n=2, so it becomes 2*x^(2-1) = 2x.',
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String questionNum,
    required String subject,
    required bool isCorrect,
    required String questionText,
    required bool hasYourAnswer,
    String? yourAnswerText,
    required String correctAnswerText,
    required String explanationTitle,
    required String explanationText,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Banner(
          message: '',
          location: BannerLocation.topStart,
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isCorrect
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  width: 5,
                ),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.close,
                          color: isCorrect
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          questionNum,
                          style: TextStyle(
                            color: isCorrect
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subject,
                        style: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Question Title
                Text(
                  questionText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Your Answer Box (If applicable)
                if (hasYourAnswer) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF451A03).withOpacity(0.3)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.red.withOpacity(0.2)
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR ANSWER',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          yourAnswerText ?? '',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Correct Answer Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF064E3B).withOpacity(0.3)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.green.withOpacity(0.2)
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CORRECT ANSWER',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            correctAnswerText,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF059669),
                        size: 22,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Explanation Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1E1B4B).withOpacity(0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF8B5CF6),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            explanationTitle,
                            style: const TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        explanationText,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
