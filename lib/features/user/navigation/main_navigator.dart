import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/core/widgets/custom_bottom_nav_bar.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/user/screens/exam_attempts_history_screen.dart';
import 'package:prep_mate/features/user/screens/show_exam_screen.dart';
import 'package:prep_mate/features/user/screens/user_home_screen.dart';
import 'package:prep_mate/features/user/screens/user_profile_screen.dart';

class MainNavigator extends StatefulWidget {
  final int initialIndex;
  const MainNavigator({super.key, this.initialIndex = 0});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> {
  late int _currentIndex;
  late final Set<int> _activatedTabs = {widget.initialIndex};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _activatedTabs.add(widget.initialIndex);
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
      _activatedTabs.add(index);
    });
  }

  late final List<Widget> _screens = [
    Userhomescreen(onNavigateToTab: switchTab),
    const Showexam(),
    const ExamAttemptsHistoryScreen(),
    const Userprofile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _activatedTabs.add(index);
    });
  }

  void _handleLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Text('Logout', style: TextStyle(color: textPrimary)),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of ExaMore?',
          style: TextStyle(color: textSecondary),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onItemTapped(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.background(isDark);
    final sidebarColor = AppColors.surfaceSecondary(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          // Desktop 2-column layout matching the reference screenshots
          return Scaffold(
            backgroundColor: bgColor,
            body: Row(
              children: [
                // Left Permanent Sidebar
                Container(
                  width: 230,
                  decoration: BoxDecoration(
                    color: sidebarColor,
                    border: Border(
                      right: BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // ExaMore Brand
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/image/examore_logo.png',
                              height: 36,
                              width: 36,
                              errorBuilder: (ctx, _, __) => const Icon(
                                Icons.school_rounded,
                                size: 32,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ExaMore',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSidebarItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        index: 0,
                      ),
                      _buildSidebarItem(
                        icon: Icons.assignment_rounded,
                        label: 'Exams',
                        index: 1,
                      ),
                      _buildSidebarItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'Results',
                        index: 2,
                      ),
                      _buildSidebarItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        index: 3,
                      ),
                      const Spacer(),
                      // Logout at the bottom of sidebar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _handleLogout,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    size: 20,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content Screen
                Expanded(
                  child: Container(
                    color: bgColor,
                    child: IndexedStack(
                      index: _currentIndex,
                      children: List.generate(_screens.length, (i) {
                        return _activatedTabs.contains(i)
                            ? _screens[i]
                            : const SizedBox.shrink();
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile / Tablet with Bottom Navigation Bar
        return Scaffold(
          backgroundColor: bgColor,
          body: IndexedStack(
            index: _currentIndex,
            children: List.generate(_screens.length, (i) {
              return _activatedTabs.contains(i)
                  ? _screens[i]
                  : const SizedBox.shrink();
            }),
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            activeColor: const Color(0xFF7C3AED),
            items: const [
              CustomBottomNavItem(
                activeIcon: Icons.home_rounded,
                inactiveIcon: Icons.home_outlined,
                label: 'Home',
              ),
              CustomBottomNavItem(
                activeIcon: Icons.assignment_rounded,
                inactiveIcon: Icons.assignment_outlined,
                label: 'Exams',
              ),
              CustomBottomNavItem(
                activeIcon: Icons.bar_chart_rounded,
                inactiveIcon: Icons.bar_chart_outlined,
                label: 'Results',
              ),
              CustomBottomNavItem(
                activeIcon: Icons.person_rounded,
                inactiveIcon: Icons.person_outline_rounded,
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
