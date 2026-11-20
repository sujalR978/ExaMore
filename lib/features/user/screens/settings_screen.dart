import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/core/theme/theme_provider.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';
import 'package:prep_mate/features/user/screens/personal_information_screen.dart';
import 'package:prep_mate/features/user/screens/privacy_policy_screen.dart';
import 'package:prep_mate/features/user/screens/saved_exam_screen.dart';

class Settingscreen extends StatefulWidget {
  const Settingscreen({super.key});

  @override
  State<Settingscreen> createState() => _SettingscreenState();
}

class _SettingscreenState extends State<Settingscreen> {
  bool _emailNotifications = true;
  bool _examReminders = false;
  bool _isDeleting = false;

  Future<void> _handleDeleteAccount() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text('Delete Account?', style: TextStyle(color: textPrimary)),
          ],
        ),
        content: Text(
          'This action is irreversible. All your profile records, saved exams, and submissions will be permanently deleted.',
          style: TextStyle(fontSize: 14, color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await AuthService().deleteAccount();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.code == 'requires-recent-login'
              ? 'Security Requirement: Please log out and log back in before deleting your account.'
              : 'Failed to delete account: ${e.message}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = AppColors.background(isDark);
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final textMuted = AppColors.textMuted(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.settings_outlined, color: textPrimary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Settings',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
              child: Text(
                'Theme',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Theme Mode Selector Card
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            themeProvider.themeMode == ThemeMode.dark
                                ? Icons.dark_mode_outlined
                                : (themeProvider.themeMode == ThemeMode.light
                                    ? Icons.light_mode_outlined
                                    : Icons.brightness_auto_outlined),
                            color: const Color(0xFF7C3AED),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appearance',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Customize application visual theme',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildThemeOption(
                          context,
                          title: 'Light',
                          icon: Icons.light_mode_rounded,
                          isSelected: themeProvider.themeMode == ThemeMode.light,
                          onTap: () => themeProvider.setLightTheme(),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context,
                          title: 'Dark',
                          icon: Icons.dark_mode_rounded,
                          isSelected: themeProvider.themeMode == ThemeMode.dark,
                          onTap: () => themeProvider.setDarkTheme(),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context,
                          title: 'System',
                          icon: Icons.settings_brightness_rounded,
                          isSelected: themeProvider.themeMode == ThemeMode.system,
                          onTap: () => themeProvider.setSystemTheme(),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
              child: Text(
                'Preferences',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Notifications & Reminders Preferences Card
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                children: [
                  // Email Notifications
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF7C3AED),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Notifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Receive exam results, scores, and updates via email',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _emailNotifications,
                          activeColor: const Color(0xFF7C3AED),
                          onChanged: (val) {
                            setState(() => _emailNotifications = val);
                          },
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: borderColor),

                  // Study Streak Reminders
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Color(0xFF7C3AED),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Study Streak Reminders',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Daily reminders to keep your active study streak',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _examReminders,
                          activeColor: const Color(0xFF7C3AED),
                          onChanged: (val) {
                            setState(() => _examReminders = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
              child: Text(
                'Account & Legal',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Account & Legal List Card
            Material(
              color: cardColor,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor, width: 1),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Personal Information',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Update your name, email and academic details',
                      style: TextStyle(color: textMuted, fontSize: 11.5),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: textMuted,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PersonalInformationScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: borderColor),
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Instructor Code',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Connect with your instructor',
                      style: TextStyle(color: textMuted, fontSize: 11.5),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: textMuted,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PersonalInformationScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: borderColor),
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bookmark_outline_rounded,
                        color: Color(0xFF7C3AED),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Saved Exams',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'View your saved or bookmarked exams',
                      style: TextStyle(color: textMuted, fontSize: 11.5),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: textMuted,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SavedExamsScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: borderColor),
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: textMuted,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: borderColor),
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_forever_outlined,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                    title: const Text(
                      'Delete Account & Data',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Permanent deletion of your student account and test history',
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                    trailing: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEF4444),
                            ),
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: textMuted,
                          ),
                    onTap: _isDeleting ? null : _handleDeleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7C3AED).withOpacity(0.15)
                : (isDark ? const Color(0xFF13192B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : (isDark ? const Color(0xFF28334D) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF7C3AED) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
