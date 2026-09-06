import 'package:flutter/material.dart';
import 'package:prep_mate/features/User/screen/examDetail.dart';
import 'package:prep_mate/features/User/widget/examCardWidget.dart';

class Userhomescreen extends StatefulWidget {
  const Userhomescreen({super.key});

  @override
  State<Userhomescreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Userhomescreen> {
  void _handleViewAll(BuildContext context) {
    print('View All clicked');
  }

  void _handleViewDetails(BuildContext context, String examTitle) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ExamdetailPage()));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Dynamic colors based on active theme mode
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
    final badgeBg = isDarkMode
        ? const Color(0xFF2E2A72)
        : const Color(0xFFDBEAFE);
    final badgeText = isDarkMode
        ? const Color(0xFF93C5FD)
        : const Color(0xFF1D4ED8);

    return Scaffold(
      backgroundColor: backgroundColor,
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
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(
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
                        print('Notifications clicked');
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
              'Hi, Alex!',
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
                        '85%',
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
                      const Text(
                        '12',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Days',
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
                    'Keep it up! Consistency is key.',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                ],
              ),
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

            // Exam Card 1: Organic Chemistry using separate ExamCard widget
            ExamCard(
              badgeText: 'SCIENCE',
              badgeColor: badgeBg,
              badgeTextColor: badgeText,
              title: 'Organic Chemistry Finals',
              time: '60 mins',
              mcqs: '50 MCQs',
              icon: Icons.science_outlined,
              isDarkMode: isDarkMode,
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              onViewDetails: () =>
                  _handleViewDetails(context, 'Organic Chemistry Finals'),
            ),
            const SizedBox(height: 16),

            // Exam Card 2: Advanced Mathematics using separate ExamCard widget
            ExamCard(
              badgeText: 'MATH',
              badgeColor: isDarkMode
                  ? const Color(0xFF451A03)
                  : const Color(0xFFFEF3C7),
              badgeTextColor: isDarkMode
                  ? const Color(0xFFFCD34D)
                  : const Color(0xFFB45309),
              title: 'Advanced Mathematics',
              time: '90 mins',
              mcqs: '75 MCQs',
              icon: Icons.calculate_outlined,
              isDarkMode: isDarkMode,
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              onViewDetails: () =>
                  _handleViewDetails(context, 'Advanced Mathematics'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),

      // Capsule-shaped Floating Bottom Navigation Bar
    );
  }
}
