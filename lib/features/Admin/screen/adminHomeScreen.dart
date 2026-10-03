import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/screen/ExamConfigurationScreen.dart';
import 'package:prep_mate/features/Admin/screen/StudentDirectoryScreen.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';
import 'package:prep_mate/features/Admin/screen/questionBankScreen.dart';
import 'package:prep_mate/features/Admin/screen/showExamesScreen.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';


class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ExamService _examService = ExamService();

  void _handleBoxTap(String boxTitle) {
    if (boxTitle == 'Total Students') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const StudentDirectoryScreen()),
      );
    }
    if (boxTitle == 'Active Exams') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const Showexamesscreen()));
    }
    if (boxTitle == 'Total Quizzes Bank') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const QuestionBankScreen()),
      );
    }
  }

  void _handleCreateNewExam() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ExamConfigurationScreen()),
    );
  }

  void _handleQuestionBank() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const QuestionBankScreen()));
  }

  void _handleViewAllActivity() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Displaying full administrative activity log.'),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
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
                    IconButton(
                      icon: Stack(
                        children: [
                          Icon(Icons.notifications_outlined, color: textColor),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<Map<String, int>>(
        stream: _examService.getDashboardMetricsStream(),
        builder: (context, metricSnapshot) {
          final metrics =
              metricSnapshot.data ??
              {'totalStudents': 12450, 'activeExams': 0, 'totalQuizzesBank': 0};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Admin Banner Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back, Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'System is running optimally. ${metrics['activeExams']} exams currently active.',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleCreateNewExam,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFBBF24),
                                foregroundColor: const Color(0xFF1E1B4B),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Create New Exam',
                                    style: TextStyle(
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _handleQuestionBank,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white54,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.layers_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Question Bank',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stat Card 1: Total Students
                _buildClickableStatCard(
                  title: 'Total Students',
                  value: '${metrics['totalStudents']}',
                  badgeText: '+14% this month',
                  isPositive: true,
                  icon: Icons.people_outline,
                  containerColor: containerColor,
                  textColor: textColor,
                  borderColor: borderColor,
                  isDarkMode: isDarkMode,
                  onTap: () => _handleBoxTap('Total Students'),
                ),
                const SizedBox(height: 16),

                // Stat Card 2: Active Exams
                _buildClickableStatCard(
                  title: 'Active Exams',
                  value: '${metrics['activeExams']}',
                  badgeText: 'live in database',
                  isPositive: false,
                  icon: Icons.assignment_outlined,
                  containerColor: containerColor,
                  textColor: textColor,
                  borderColor: borderColor,
                  isDarkMode: isDarkMode,
                  onTap: () => _handleBoxTap('Active Exams'),
                ),
                const SizedBox(height: 16),

                // Stat Card 3: Total Quizzes Bank
                _buildClickableStatCard(
                  title: 'Total Quizzes Bank',
                  value: '${metrics['totalQuizzesBank']}',
                  badgeText: 'curated questions',
                  isPositive: true,
                  icon: Icons.help_outline,
                  containerColor: containerColor,
                  textColor: textColor,
                  borderColor: borderColor,
                  isDarkMode: isDarkMode,
                  onTap: () => _handleBoxTap('Total Quizzes Bank'),
                ),
                const SizedBox(height: 24),

                // Recent Activity Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDarkMode ? 0.2 : 0.02,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: _handleViewAllActivity,
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                color: Color(0xFF7C3AED),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _examService.getRecentActivitiesStream(),
                        builder: (context, actSnapshot) {
                          final activities = actSnapshot.data ?? [];

                          if (activities.isEmpty) {
                            return Column(
                              children: [
                                _buildActivityItem(
                                  icon: Icons.arrow_upward,
                                  iconBg: const Color(0xFFD1FAE5),
                                  iconColor: const Color(0xFF059669),
                                  title: 'Exam Management Online',
                                  description:
                                      'Database sync active across all exam cohorts.',
                                  time: 'Just now',
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                  isDarkMode: isDarkMode,
                                ),
                                const Divider(height: 24),
                                _buildActivityItem(
                                  icon: Icons.person_add_outlined,
                                  iconBg: const Color(0xFFDBEAFE),
                                  iconColor: const Color(0xFF2563EB),
                                  title: 'Realtime Service Connected',
                                  description:
                                      'Question bank and student tracking active.',
                                  time: '1 hour ago',
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                  isDarkMode: isDarkMode,
                                ),
                              ],
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activities.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final item = activities[index];
                              final time = item['timestamp'] != null
                                  ? _formatTimeAgo(
                                      (item['timestamp'] as Timestamp).toDate(),
                                    )
                                  : 'Recently';

                              return _buildActivityItem(
                                icon: Icons.notifications_active_outlined,
                                iconBg: const Color(0xFFDBEAFE),
                                iconColor: const Color(0xFF2563EB),
                                title: item['title'] ?? 'System Event',
                                description: item['description'] ?? '',
                                time: time,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                isDarkMode: isDarkMode,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClickableStatCard({
    required String title,
    required String value,
    required String badgeText,
    required bool isPositive,
    required IconData icon,
    required Color containerColor,
    required Color textColor,
    required Color borderColor,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF312E81)
                          : const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isDarkMode
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1D4ED8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFF94A3B8)
                          : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badgeText,
                    style: TextStyle(
                      color: isPositive
                          ? const Color(0xFF10B981)
                          : (isDarkMode
                                ? const Color(0xFF94A3B8)
                                : Colors.grey[600]),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    required Color textColor,
    required Color subtitleColor,
    required bool isDarkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDarkMode ? const Color(0xFFFBBF24) : iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: TextStyle(
                  color: subtitleColor.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
