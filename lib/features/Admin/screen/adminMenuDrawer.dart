import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/screen/ExamConfigurationScreen.dart';
import 'package:prep_mate/features/Admin/screen/ReviewAndPublishScreen.dart';
import 'package:prep_mate/features/Admin/screen/StudentDirectoryScreen.dart';
import 'package:prep_mate/features/Admin/screen/adminHomeScreen.dart';
import 'package:prep_mate/features/Admin/screen/questionBankScreen.dart';
import 'package:prep_mate/features/Admin/screen/showExamesScreen.dart';
import 'package:prep_mate/features/Admin/screen/supportScreen.dart';
import 'package:prep_mate/features/Admin/screen/userResultScreen.dart';
import 'package:prep_mate/features/User/screen/activeExamScreen.dart';
import 'package:prep_mate/features/User/screen/presnoalInformation.dart';
import 'package:prep_mate/features/User/screen/showExam.dart';

class AdminMenuDrawer extends StatelessWidget {
  const AdminMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final backgroundColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;

    return Drawer(
      backgroundColor: backgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E1B4B)
                  : const Color(0xFF1E1B4B),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Examora Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Navigation & Management',
                  style: TextStyle(color: subtitleColor, fontSize: 13),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.dashboard_outlined,
              color: Color(0xFF7C3AED),
            ),
            title: Text(
              'Admin Dashboard',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AdminHomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF2563EB),
            ),
            title: Text(
              'Active Exams',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Showexamesscreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.settings_applications_outlined,
              color: Color(0xFFD97706),
            ),
            title: Text(
              'Exam Configuration',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ExamConfigurationScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.layers_outlined,
              color: Color(0xFF059669),
            ),
            title: Text(
              'Question Bank',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => QuestionBankScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.rate_review_outlined,
              color: Color(0xFF7C3AED),
            ),
            title: Text(
              'Review & Publish',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReviewAndPublishScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline, color: Color(0xFF2563EB)),
            title: Text(
              'Recent Results & Users',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RecentResultsAndUsersScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined, color: Color(0xFF059669)),
            title: Text(
              'Student Directory',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StudentDirectoryScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.support_agent_outlined,
              color: Color(0xFFDC2626),
            ),
            title: Text(
              'Support Overview',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SupportOverviewScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
