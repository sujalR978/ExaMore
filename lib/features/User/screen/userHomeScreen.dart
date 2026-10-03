import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';
import 'package:prep_mate/features/User/screen/allExamScreen.dart';
import 'package:prep_mate/features/User/screen/examDetail.dart';
import 'package:prep_mate/features/User/screen/settingScreen.dart';
import 'package:prep_mate/features/User/widget/examCardWidget.dart';

class Userhomescreen extends StatefulWidget {
  const Userhomescreen({super.key});

  @override
  State<Userhomescreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Userhomescreen> {
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  void _handleViewAll(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AllExamsScreen()));
  }

  void _handleViewDetails(BuildContext context, ExamModel exam) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ExamdetailPage(exam: exam)));
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'science':
      case 'physics':
      case 'chemistry':
      case 'biology':
        return Icons.science_outlined;
      case 'mathematics':
      case 'math':
        return Icons.calculate_outlined;
      case 'history':
        return Icons.history_edu_outlined;
      case 'computer science':
        return Icons.computer_outlined;
      case 'literature':
        return Icons.auto_stories_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode
        ? const Color(0xFF0F0E17)
        : Colors.grey[100]!;
    final containerColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = isDarkMode
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF1E1B4B);
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    final displayName = _currentUser?.displayName ?? 'Alex';

    return Scaffold(
      backgroundColor: backgroundColor,
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
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(
                        _currentUser?.photoURL ??
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
                      ),
                    ),
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
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: textColor,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const Settingscreen(),
                          ),
                        );
                      },
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
            const SizedBox(height: 8),
            // Header Greeting
            Text(
              'Hi, $displayName!',
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready for your next challenge? Your flow state awaits.',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),

            // Realtime Dynamic Overall Progress & Study Streak
            StreamBuilder<Map<String, int>>(
              stream: _examService.getUserPerformanceMetricsStream(
                _currentUser?.uid ?? '',
              ),
              builder: (context, metricSnapshot) {
                final metrics =
                    metricSnapshot.data ??
                    {'overallProgress': 0, 'studyStreak': 0};

                final progress = metrics['overallProgress'] ?? 0;
                final streak = metrics['studyStreak'] ?? 0;

                return Column(
                  children: [
                    // Overall Progress Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OVERALL PROGRESS',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$progress%',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF312E81)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.show_chart,
                              color: isDarkMode
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFF2563EB),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Study Streak Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Study Streak',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$streak',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                streak == 1 ? 'Day' : 'Days',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            streak > 0
                                ? 'Keep it up! Consistency is key.'
                                : 'Complete your first assessment today to start a streak!',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Available Exams Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Exams',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _handleViewAll(context),
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: isDarkMode
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFB45309),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Stream of Published Exams from Firebase
            StreamBuilder<List<ExamModel>>(
              stream: _examService.getPublishedExamsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'Unable to load exams: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final exams = snapshot.data ?? [];

                if (exams.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(
                        'No published exams available yet.\nPlease check back later!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                    ),
                  );
                }

                // Show top 3 published exams on the home dashboard
                final displayExams = exams.take(3).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayExams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final exam = displayExams[index];
                    final isScience =
                        exam.category.toLowerCase().contains('sci') ||
                        exam.category.toLowerCase().contains('bio') ||
                        exam.category.toLowerCase().contains('chem');

                    final badgeBg = isScience
                        ? (isDarkMode
                              ? const Color(0xFF2E2A72)
                              : const Color(0xFFDBEAFE))
                        : (isDarkMode
                              ? const Color(0xFF451A03)
                              : const Color(0xFFFEF3C7));

                    final badgeText = isScience
                        ? (isDarkMode
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1D4ED8))
                        : (isDarkMode
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFFB45309));

                    return ExamCard(
                      badgeText: exam.category.toUpperCase(),
                      badgeColor: badgeBg,
                      badgeTextColor: badgeText,
                      title: exam.title,
                      time: '${exam.durationMinutes} mins',
                      mcqs: '${exam.questions.length} MCQs',
                      icon: _getCategoryIcon(exam.category),
                      isDarkMode: isDarkMode,
                      containerColor: containerColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      onViewDetails: () => _handleViewDetails(context, exam),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
