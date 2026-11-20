import 'package:flutter/material.dart';

class CustomBottomNavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final String? badgeText;

  const CustomBottomNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    this.badgeText,
  });
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CustomBottomNavItem> items;
  final Color activeColor;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor = const Color(0xFF7C3AED),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF13192B) : theme.colorScheme.surface;
    final borderColor = isDarkMode ? const Color(0xFF28334D) : Colors.grey.shade200;
    final inactiveColor =
        isDarkMode ? const Color(0xFF94A3B8) : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkResponse(
                    onTap: () => onTap(index),
                    highlightColor: Colors.transparent,
                    splashColor: activeColor.withOpacity(0.12),
                    radius: 36,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.inactiveIcon,
                                size: 22,
                                color: isSelected ? Colors.white : inactiveColor,
                              ),
                              if (item.badgeText != null &&
                                  item.badgeText!.isNotEmpty)
                                Positioned(
                                  top: -4,
                                  right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item.badgeText!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDarkMode
                                    ? const Color(0xFFA78BFA)
                                    : const Color(0xFF7C3AED))
                                : inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

