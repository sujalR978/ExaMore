import 'package:flutter/material.dart';

import 'package:prep_mate/features/User/screen/showExam.dart';
import 'package:prep_mate/features/User/screen/userHomeScreen.dart';
import 'package:prep_mate/features/User/screen/userProfile.dart';

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
    const PlaceholderScreen(title: 'Practice / Results'),
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
    final isDarkMode = theme.brightness == Brightness.dark;
    final containerColor = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Using a Stack so the bottom nav bar floats transparently over the content
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          100.0,
        ), // Added 100px bottom padding so content scrolls above the capsule bar
        child: Column(
          children: [
            // Screens take up the full body
            IndexedStack(index: _currentIndex, children: _screens),

            // Floating Capsule Navigation Bar positioned at the bottom
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: SafeArea(
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDarkMode ? 0.35 : 0.1,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        0,
                        Icons.dashboard_outlined,
                        Icons.dashboard,
                        'Dashboard',
                        isDarkMode,
                      ),
                      _buildNavItem(
                        1,
                        Icons.assignment,
                        Icons.assignment_outlined,
                        'Exams',
                        isDarkMode,
                      ),
                      _buildNavItem(
                        2,
                        Icons.bolt,
                        Icons.bolt_outlined,
                        'Practice',
                        isDarkMode,
                      ),
                      _buildNavItem(
                        3,
                        Icons.person,
                        Icons.person_outline,
                        'Profile',
                        isDarkMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    bool isDarkMode,
  ) {
    final bool isSelected = _currentIndex == index;
    final selectedBg = isDarkMode
        ? const Color(0xFF312E81)
        : const Color(0xFFFEF3C7);
    final selectedColor = isDarkMode
        ? const Color(0xFFFBBF24)
        : const Color(0xFFB45309);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? selectedColor : Colors.grey[500],
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selectedColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
