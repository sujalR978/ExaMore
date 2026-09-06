import 'package:flutter/material.dart';

class ExamCard extends StatefulWidget {
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String title;
  final String time;
  final String mcqs;
  final IconData icon;
  final bool isDarkMode;
  final Color containerColor;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final VoidCallback onViewDetails;

  const ExamCard({
    super.key,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.title,
    required this.time,
    required this.mcqs,
    required this.icon,
    required this.isDarkMode,
    required this.containerColor,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.onViewDetails,
  });

  @override
  State<ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<ExamCard> {
  // Separate method for the action button
  Widget _buildActionButton() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: widget.onViewDetails,
        icon: Icon(
          Icons.arrow_forward_rounded,
          color: widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
          size: 20,
        ),
        tooltip: 'View Details',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              Icon(widget.icon, color: widget.subtitleColor, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: widget.subtitleColor),
                  const SizedBox(width: 4),
                  Text(
                    widget.time,
                    style: TextStyle(color: widget.subtitleColor, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.list_alt, size: 16, color: widget.subtitleColor),
                  const SizedBox(width: 4),
                  Text(
                    widget.mcqs,
                    style: TextStyle(color: widget.subtitleColor, fontSize: 13),
                  ),
                ],
              ),
              // Action Button replacement
              _buildActionButton(),
            ],
          ),
        ],
      ),
    );
  }
}