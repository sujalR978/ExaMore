import 'package:flutter/material.dart';
import 'package:prep_mate/core/widgets/app_image_view.dart';

class QuestionOptionTile extends StatelessWidget {
  final int index;
  final String optionLetter;
  final TextEditingController controller;
  final bool isCorrect;
  final String? imageUrl;
  final bool canRemove;
  final bool isDarkMode;
  final Color containerColor;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final VoidCallback onTapCorrect;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onRemoveOption;

  const QuestionOptionTile({
    super.key,
    required this.index,
    required this.optionLetter,
    required this.controller,
    required this.isCorrect,
    this.imageUrl,
    required this.canRemove,
    required this.isDarkMode,
    required this.containerColor,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.onTapCorrect,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onRemoveOption,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasOptionImg = imageUrl != null && imageUrl!.isNotEmpty;

    return InkWell(
      onTap: onTapCorrect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isCorrect
              ? const Color(0xFF10B981).withValues(alpha: 0.08)
              : containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect ? const Color(0xFF10B981) : borderColor,
            width: isCorrect ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Option Letter / Correct Badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCorrect
                    ? const Color(0xFF10B981)
                    : (isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isCorrect
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        optionLetter,
                        style: TextStyle(
                          color: subtitleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight:
                      isCorrect ? FontWeight.w600 : FontWeight.normal,
                ),
                decoration: InputDecoration(
                  hintText: 'Option $optionLetter text...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white38 : Colors.grey[400],
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 6,
                  ),
                ),
              ),
            ),

            // Option Image thumbnail or picker
            if (hasOptionImg) ...[
              const SizedBox(width: 6),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AppImageView(
                      imageSource: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: onRemoveImage,
                      child: const CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.black87,
                        child: Icon(
                          Icons.close,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              IconButton(
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 18,
                ),
                color: subtitleColor,
                tooltip: 'Attach image to this option',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: onPickImage,
              ),
            ],

            if (isCorrect)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Correct',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            if (canRemove)
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 22, minHeight: 22),
                onPressed: onRemoveOption,
              ),
          ],
        ),
      ),
    );
  }
}
