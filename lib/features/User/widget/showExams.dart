import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// 1. Separate Stateful Widget for the Exam Card
// ---------------------------------------------------------------------------
class ExamCardWidget extends StatefulWidget {
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String title;
  final String description;
  final String time;
  final String mcqs;
  final IconData icon;
  final bool isBookmarked;
  final String buttonText;
  final Color buttonBgColor;
  final Color buttonTextColor;
  final VoidCallback onButtonPressed;

  const ExamCardWidget({
    super.key,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.title,
    required this.description,
    required this.time,
    required this.mcqs,
    required this.icon,
    required this.isBookmarked,
    required this.buttonText,
    required this.buttonBgColor,
    required this.buttonTextColor,
    required this.onButtonPressed,
  });

  @override
  State<ExamCardWidget> createState() => _ExamCardWidgetState();
}

class _ExamCardWidgetState extends State<ExamCardWidget> {
  late bool _bookmarked;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.isBookmarked;
  }

  void _toggleBookmark() {
    setState(() {
      _bookmarked = !_bookmarked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.badgeText,
                  style: TextStyle(
                    color: widget.badgeTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _bookmarked ? const Color(0xFFF59E0B) : subtitleColor,
                ),
                onPressed: _toggleBookmark,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.description,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: subtitleColor),
              const SizedBox(width: 4),
              Text(
                widget.time,
                style: TextStyle(color: subtitleColor, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.list_alt, size: 16, color: subtitleColor),
              const SizedBox(width: 4),
              Text(
                widget.mcqs,
                style: TextStyle(color: subtitleColor, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.buttonBgColor,
                foregroundColor: widget.buttonTextColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}