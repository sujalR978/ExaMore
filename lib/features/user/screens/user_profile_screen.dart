// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';
import 'package:prep_mate/features/user/screens/personal_information_screen.dart';
import 'package:prep_mate/features/user/screens/privacy_policy_screen.dart';
import 'package:prep_mate/features/user/screens/saved_exam_screen.dart';
import 'package:prep_mate/features/user/screens/settings_screen.dart';
import 'package:prep_mate/features/user/screens/support_center_screen.dart';
import 'package:prep_mate/core/widgets/app_image_view.dart';

class Userprofile extends StatefulWidget {
  const Userprofile({super.key});

  @override
  State<Userprofile> createState() => _UserProfileState();
}

class _UserProfileState extends State<Userprofile> {
  bool _isLoggingOut = false;
  final ExamService _examService = ExamService();
  late Future<Map<String, dynamic>?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    if (user.email == 'admin@gmail.com') {
      return {
        'name': 'Admin User',
        'email': 'admin@gmail.com',
        'photoUrl': 'assets/image/L_image.png',
        'academicLevel': 'System Administrator',
        'major': 'Computer Science',
        'adminId': 'root_admin',
      };
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  void _refreshProfile() {
    setState(() {
      _userDataFuture = _fetchUserData();
    });
  }

  void _handleMenuAction(String title) async {
    if (title == 'Personal Information') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PersonalInformationScreen(),
        ),
      );
      _refreshProfile();
    } else if (title == 'Saved Exams') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const SavedExamsScreen()));
      _refreshProfile();
    } else if (title == 'Settings') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const Settingscreen()));
      _refreshProfile();
    } else if (title == 'Help & Support') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SupportCenterScreen()),
      );
      _refreshProfile();
    } else if (title == 'Privacy Policy') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
      );
    }
  }

  void _handleLogout() async {
    // 1. Set logging out state to prevent UI flickers
    setState(() => _isLoggingOut = true);

    // 2. Show a clean blocking overlay so the cleared profile is never shown
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      ),
    );

    try {
      final AuthService authService = AuthService();
      await authService.signOut();

      if (!mounted) return;

      // 3. Clear navigation stack and route to Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        // Dismiss loading dialog if sign out fails
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bgColor = AppColors.background(isDarkMode);
    final cardColor = AppColors.card(isDarkMode);
    final surfaceSec = AppColors.surfaceSecondary(isDarkMode);
    final borderColor = AppColors.border(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final textMuted = AppColors.textMuted(isDarkMode);

    final user = FirebaseAuth.instance.currentUser;
    final String currentUserId = user?.uid ?? '';

    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data;
        final String displayName = userData?['name'] ?? 'User';
        final String displayEmail = userData?['email'] ?? '';
        final String adminId = (userData?['adminId'] ?? '').toString();

        final String photoUrl =
            userData?['photoUrl']?.toString().isNotEmpty == true
            ? userData!['photoUrl'].toString()
            : 'assets/image/L_image.png';

        final String academicLevel = userData?['academicLevel'] ?? 'Year 3';
        final String major = userData?['major'] ?? 'Science Major';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Profile',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your account and academic details.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.18),
                  side: const BorderSide(color: Color(0xFF7C3AED), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: Color(0xFF7C3AED),
                ),
                label: Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PersonalInformationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: textSecondary),
                tooltip: 'Settings',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Settingscreen(),
                    ),
                  );
                  _refreshProfile();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Main Card (Reference Layout)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.35)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4C1D95),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child:
                                    (photoUrl.isNotEmpty &&
                                        photoUrl != 'assets/image/L_image.png')
                                    ? AppImageView(
                                        imageSource: photoUrl,
                                        fit: BoxFit.cover,
                                        width: 68,
                                        height: 68,
                                        placeholder: Center(
                                          child: Text(
                                            displayName.isNotEmpty
                                                ? displayName[0].toUpperCase()
                                                : 'J',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        errorWidget: Center(
                                          child: Text(
                                            displayName.isNotEmpty
                                                ? displayName[0].toUpperCase()
                                                : 'J',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          displayName.isNotEmpty
                                              ? displayName[0].toUpperCase()
                                              : 'J',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  displayEmail.isNotEmpty
                                      ? displayEmail
                                      : 'student@university.edu',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _buildTag(
                                      Icons.science_outlined,
                                      major,
                                      isDarkMode,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTag(
                                      Icons.calendar_today_outlined,
                                      academicLevel,
                                      isDarkMode,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 16),
                      // Four Stats Cards inside Profile
                      StreamBuilder<List<dynamic>>(
                        stream: _examService.getUserExamAttemptsStream(
                          currentUserId,
                        ),
                        builder: (context, attemptSnap) {
                          final attempts = attemptSnap.data ?? [];
                          final int examsCount = attempts.length;
                          double bestScore = 0;
                          for (var att in attempts) {
                            final sub =
                                att['submission'] as StudentSubmissionModel?;
                            if (sub != null &&
                                sub.scorePercentage > bestScore) {
                              bestScore = sub.scorePercentage;
                            }
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.layers_outlined,
                                  iconColor: const Color(0xFF7C3AED),
                                  value: '0',
                                  label: 'Classrooms',
                                  surfaceColor: surfaceSec,
                                  borderColor: borderColor,
                                  textColor: textPrimary,
                                  labelColor: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.assignment_outlined,
                                  iconColor: const Color(0xFF7C3AED),
                                  value: '$examsCount',
                                  label: 'Exams Taken',
                                  surfaceColor: surfaceSec,
                                  borderColor: borderColor,
                                  textColor: textPrimary,
                                  labelColor: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.emoji_events_outlined,
                                  iconColor: const Color(0xFFF59E0B),
                                  value: examsCount > 0
                                      ? '${bestScore.toInt()}%'
                                      : '-',
                                  label: 'Best Score',
                                  surfaceColor: surfaceSec,
                                  borderColor: borderColor,
                                  textColor: textPrimary,
                                  labelColor: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.trending_up_rounded,
                                  iconColor: const Color(0xFF10B981),
                                  value: examsCount > 0
                                      ? '${bestScore.toInt()}%'
                                      : '0%',
                                  label: 'Overall Progress',
                                  surfaceColor: surfaceSec,
                                  borderColor: borderColor,
                                  textColor: textPrimary,
                                  labelColor: textSecondary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Account Management Menu
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildMenuRow(
                        Icons.person_outline_rounded,
                        'Personal Information',
                        textPrimary,
                        textSecondary,
                        () => _handleMenuAction('Personal Information'),
                      ),

                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.settings_outlined,
                        'Settings',
                        textPrimary,
                        textSecondary,
                        () => _handleMenuAction('Settings'),
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.privacy_tip_outlined,
                        'Privacy Policy',
                        textPrimary,
                        textSecondary,
                        () => _handleMenuAction('Privacy Policy'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoggingOut ? null : _handleLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoggingOut)
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEF4444),
                            ),
                          )
                        else
                          const Icon(Icons.logout_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _isLoggingOut ? 'Logging out...' : 'Logout',
                          style: const TextStyle(
                            fontSize: 14,
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
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    Color? surfaceColor,
    Color? borderColor,
    Color? textColor,
    Color? labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor ?? const Color(0xFF13192B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? const Color(0xFF28334D),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor ?? const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: labelColor ?? const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF7C3AED).withOpacity(0.12)
            : const Color(0xFF7C3AED).withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(
    IconData icon,
    String title,
    Color textColor,
    Color subtitleColor,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              )
            : null,
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor),
        onTap: onTap,
      ),
    );
  }
}
