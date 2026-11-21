import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/core/utils/dialog_utils.dart';
import 'package:prep_mate/features/admin/screens/student_directory_screen.dart';
import 'package:prep_mate/features/admin/screens/admin_directory_screen.dart';
import 'package:prep_mate/features/admin/screens/admin_home_screen.dart';
import 'package:prep_mate/features/admin/screens/question_bank_screen.dart';
import 'package:prep_mate/features/admin/screens/show_exams_screen.dart';
import 'package:prep_mate/features/admin/screens/user_result_screen.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';
import 'package:prep_mate/features/user/screens/settings_screen.dart';
import 'package:prep_mate/features/user/screens/user_profile_screen.dart';

class AdminMenuDrawer extends StatefulWidget {
  const AdminMenuDrawer({super.key});

  @override
  State<AdminMenuDrawer> createState() => _AdminMenuDrawerState();
}

class _AdminMenuDrawerState extends State<AdminMenuDrawer> {
  late final Future<bool> _superAdminFuture;

  @override
  void initState() {
    super.initState();
    _superAdminFuture = _isSuperAdmin();
  }

  Future<bool> _isSuperAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Hardcoded Super Admin check
    if (user.email?.toLowerCase() == 'admin@gmail.com') {
      return true;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final role = (doc.data()?['role'] ?? '').toString().toLowerCase();
        return role == 'super_admin';
      }
    } catch (_) {}

    return false;
  }

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
            decoration: const BoxDecoration(color: Color(0xFF1E1B4B)),
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
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AdminHomeScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const Showexamesscreen(),
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
                MaterialPageRoute(
                  builder: (context) => const QuestionBankScreen(),
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
                  builder: (context) => const RecentResultsAndUsersScreen(),
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
                  builder: (context) => const StudentDirectoryScreen(),
                ),
              );
            },
          ),

          // Only Super Admin can view Registered Instructors
          FutureBuilder<bool>(
            future: _superAdminFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return ListTile(
                  leading: const Icon(
                    Icons.badge_rounded,
                    color: Color(0xFFDC2626),
                  ),
                  title: Text(
                    'Registered Instructors',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminDirectoryScreen(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const Divider(height: 24, thickness: 1),

          ListTile(
            leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF7C3AED)),
            title: Text(
              'My Profile',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Userprofile()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
            title: Text(
              'Settings',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Settingscreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
            title: Text(
              'Log Out',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              final confirm = await DialogUtils.showLogoutConfirmation(context);
              if (confirm) {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const Login()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
