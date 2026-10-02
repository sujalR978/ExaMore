import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:prep_mate/features/Auth/screens/login.dart';
import 'package:prep_mate/features/Auth/services/auth_service.dart';
import 'package:prep_mate/features/User/screen/presnoalInformation.dart';
import 'package:prep_mate/features/User/screen/savedExamScreen.dart';
import 'package:prep_mate/features/User/screen/settingScreen.dart';
import 'package:prep_mate/features/User/screen/supportCenterScreen.dart';

class Userprofile extends StatefulWidget {
  const Userprofile({super.key});

  @override
  State<Userprofile> createState() => _profileState();
}

class _profileState extends State<Userprofile> {
  bool _isLoggingOut = false; // Track logout loading state

  // Fetch current user details from Firestore
  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Check if user is the admin fallback
    if (user.email == 'admin@gmail.com') {
      return {
        'name': 'Admin User',
        'email': 'admin@gmail.com',
        'photoUrl':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
        'academicLevel': 'System Administrator',
        'major': 'Computer Science',
      };
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  // Refreshes the profile page when returning from sub-screens
  void _refreshProfile() {
    setState(() {});
  }

  void _handleMenuAction(String title) async {
    if (title == 'Personal Information') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PersonalInformationScreen(),
        ),
      );
      _refreshProfile(); // Refresh UI with updated Firestore data
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
    }
  }

  void _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      AuthService authService = AuthService();
      await authService.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    } catch (e) {
      print("LOGOUT ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  // Helper to load either NetworkImage or FileImage dynamically
  ImageProvider _getProfileImage(String photoUrl) {
    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    } else {
      // It's a local file path saved from the image picker
      final file = File(photoUrl);
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        // Fallback if file path is invalid
        return const NetworkImage(
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
        );
      }
    }
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

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data;
        final String displayName = userData?['name'] ?? 'User';
        final String displayEmail = userData?['email'] ?? '';
        final String photoUrl =
            userData?['photoUrl'] ??
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200';
        final String academicLevel = userData?['academicLevel'] ?? 'Year 3';
        final String major = userData?['major'] ?? 'Science Major';

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
                        color: Colors.black.withOpacity(
                          isDarkMode ? 0.2 : 0.05,
                        ),
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
                          backgroundImage: _getProfileImage(photoUrl),
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
                          icon: Icon(Icons.settings_outlined, color: textColor),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const Settingscreen(),
                              ),
                            );
                            _refreshProfile();
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
                // User Header Profile Card
                Container(
                  padding: const EdgeInsets.all(24),
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
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundImage: _getProfileImage(photoUrl),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: containerColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayEmail.isNotEmpty
                            ? displayEmail
                            : 'Academic Level: $academicLevel',
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTag(Icons.science_outlined, major, isDarkMode),
                          const SizedBox(width: 8),
                          _buildTag(
                            Icons.school_outlined,
                            academicLevel,
                            isDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Badges Section Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Color(0xFFF59E0B),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Badges',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBadgeItem(
                              Icons.emoji_events,
                              const Color(0xFFFEF3C7),
                              const Color(0xFFB45309),
                              'Top Scorer',
                              isDarkMode,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBadgeItem(
                              Icons.alarm,
                              const Color(0xFFD1FAE5),
                              const Color(0xFF065F46),
                              'Early Bird',
                              isDarkMode,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBadgeItem(
                              Icons.local_fire_department_outlined,
                              const Color(0xFFEDE9FE),
                              const Color(0xFF5B21B6),
                              '7-Day Streak',
                              isDarkMode,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDashedBadge(
                              'View All',
                              borderColor,
                              textColor,
                              isDarkMode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Menu Options List Card
                Container(
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildMenuRow(
                        Icons.person_outline,
                        'Personal Information',
                        textColor,
                        subtitleColor,
                        () => _handleMenuAction('Personal Information'),
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.bookmark_border,
                        'Saved Exams',
                        textColor,
                        subtitleColor,
                        () => _handleMenuAction('Saved Exams'),
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.notifications_outlined,
                        'Notification Settings',
                        textColor,
                        subtitleColor,
                        () => _handleMenuAction('Settings'),
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.help_outline,
                        'Help & Support',
                        textColor,
                        subtitleColor,
                        () => _handleMenuAction('Help & Support'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button with Loading Indicator
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoggingOut ? null : _handleLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoggingOut)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        else
                          const Icon(Icons.logout, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isLoggingOut ? 'Logging out...' : 'Logout',
                          style: const TextStyle(
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
      },
    );
  }

  Widget _buildTag(IconData icon, String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDarkMode
                ? const Color(0xFF93C5FD)
                : const Color(0xFF1E1B4B),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFF1E1B4B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(
    IconData icon,
    Color bgCol,
    Color iconCol,
    String title,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF334155) : bgCol,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDarkMode ? const Color(0xFFFBBF24) : iconCol,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF1E1B4B),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedBadge(
    String title,
    Color borderColor,
    Color textColor,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.add, color: textColor, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
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
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor),
      onTap: onTap,
    );
  }
}
