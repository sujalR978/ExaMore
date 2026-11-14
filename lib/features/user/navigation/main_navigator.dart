import 'package:flutter/material.dart';
import 'package:prep_mate/core/widgets/custom_bottom_nav_bar.dart';
import 'package:prep_mate/features/user/screens/exam_attempts_history_screen.dart';
import 'package:prep_mate/features/user/screens/show_exam_screen.dart';
import 'package:prep_mate/features/user/screens/user_home_screen.dart';
import 'package:prep_mate/features/user/screens/user_profile_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const Userhomescreen(),
    const Showexam(),
    const ExamAttemptsHistoryScreen(),
    const Userprofile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        activeColor: const Color(0xFF7C3AED),
        items: const [
          CustomBottomNavItem(
            activeIcon: Icons.dashboard_rounded,
            inactiveIcon: Icons.dashboard_outlined,
            label: 'Home',
          ),
          CustomBottomNavItem(
            activeIcon: Icons.assignment_rounded,
            inactiveIcon: Icons.assignment_outlined,
            label: 'Exams',
          ),
          CustomBottomNavItem(
            activeIcon: Icons.emoji_events_rounded,
            inactiveIcon: Icons.emoji_events_outlined,
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
  }
}
