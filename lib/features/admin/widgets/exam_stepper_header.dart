import 'package:flutter/material.dart';

class ExamStepperHeader extends StatelessWidget {
  final int currentStep; // 1, 2, or 3
  final ValueChanged<int>? onStepTapped;

  const ExamStepperHeader({
    super.key,
    required this.currentStep,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final primaryColor = const Color(0xFF7C3AED);
    final completedColor = const Color(0xFF10B981);
    final inactiveColor = isDarkMode ? Colors.white24 : Colors.grey.shade300;
    final inactiveTextColor = isDarkMode ? Colors.white38 : Colors.grey.shade500;
    final activeTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStep(
            stepNumber: 1,
            title: 'Details',
            icon: Icons.tune_rounded,
            primaryColor: primaryColor,
            completedColor: completedColor,
            inactiveColor: inactiveColor,
            activeTextColor: activeTextColor,
            inactiveTextColor: inactiveTextColor,
          ),
          _buildConnector(
            isCompleted: currentStep > 1,
            color: currentStep > 1 ? completedColor : inactiveColor,
          ),
          _buildStep(
            stepNumber: 2,
            title: 'Questions',
            icon: Icons.quiz_outlined,
            primaryColor: primaryColor,
            completedColor: completedColor,
            inactiveColor: inactiveColor,
            activeTextColor: activeTextColor,
            inactiveTextColor: inactiveTextColor,
          ),
          _buildConnector(
            isCompleted: currentStep > 2,
            color: currentStep > 2 ? completedColor : inactiveColor,
          ),
          _buildStep(
            stepNumber: 3,
            title: 'Publish',
            icon: Icons.verified_outlined,
            primaryColor: primaryColor,
            completedColor: completedColor,
            inactiveColor: inactiveColor,
            activeTextColor: activeTextColor,
            inactiveTextColor: inactiveTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Color completedColor,
    required Color inactiveColor,
    required Color activeTextColor,
    required Color inactiveTextColor,
  }) {
    final isCompleted = currentStep > stepNumber;
    final isActive = currentStep == stepNumber;

    Color badgeBg;
    Color badgeFg;
    if (isCompleted) {
      badgeBg = completedColor;
      badgeFg = Colors.white;
    } else if (isActive) {
      badgeBg = primaryColor;
      badgeFg = Colors.white;
    } else {
      badgeBg = inactiveColor;
      badgeFg = inactiveTextColor;
    }

    return InkWell(
      onTap: onStepTapped != null ? () => onStepTapped!(stepNumber) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : Text(
                        '$stepNumber',
                        style: TextStyle(
                          color: badgeFg,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeTextColor : inactiveTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector({
    required bool isCompleted,
    required Color color,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 2.5,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

