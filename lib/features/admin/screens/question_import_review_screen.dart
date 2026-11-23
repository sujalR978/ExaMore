// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/widgets/admin_top_bar.dart';

class QuestionImportReviewScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final String examTitle;
  final double? targetTotalMarks;

  const QuestionImportReviewScreen({
    super.key,
    required this.questions,
    required this.examTitle,
    this.targetTotalMarks,
  });

  @override
  State<QuestionImportReviewScreen> createState() =>
      _QuestionImportReviewScreenState();
}

class _QuestionImportReviewScreenState
    extends State<QuestionImportReviewScreen> {
  late List<QuestionModel> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List<QuestionModel>.from(widget.questions);
  }

  double get _totalMarks =>
      _questions.fold(0.0, (sum, q) => sum + q.marks);

  int get _validCount =>
      _questions.where((q) => q.options.isNotEmpty && q.correctOptionId.isNotEmpty).length;

  void _updateCorrectOption(int qIndex, String newOptionId) {
    setState(() {
      final old = _questions[qIndex];
      _questions[qIndex] = QuestionModel(
        id: old.id,
        questionText: old.questionText,
        marks: old.marks,
        options: old.options,
        correctOptionId: newOptionId,
        type: old.type,
        category: old.category,
        difficulty: old.difficulty,
        adminId: old.adminId,
        views: old.views,
        estimatedTimeMinutes: old.estimatedTimeMinutes,
        imageUrl: old.imageUrl,
        createdAt: old.createdAt,
      );
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question removed from import'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _editQuestionMarks(int index) {
    final controller = TextEditingController(
      text: _questions[index].marks.toInt().toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Marks / Points',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newMarks = double.tryParse(controller.text.trim()) ?? _questions[index].marks;
              if (newMarks > 0) {
                setState(() {
                  final old = _questions[index];
                  _questions[index] = QuestionModel(
                    id: old.id,
                    questionText: old.questionText,
                    marks: newMarks,
                    options: old.options,
                    correctOptionId: old.correctOptionId,
                    type: old.type,
                    category: old.category,
                    difficulty: old.difficulty,
                    adminId: old.adminId,
                    views: old.views,
                    estimatedTimeMinutes: old.estimatedTimeMinutes,
                    imageUrl: old.imageUrl,
                    createdAt: old.createdAt,
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor =
        isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AdminTopBar(
        title: 'Review Question Bank',
        subtitle: '${_questions.length} questions parsed for ${widget.examTitle.isEmpty ? "Exam" : widget.examTitle}',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: _questions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 54, color: subtitleColor),
                  const SizedBox(height: 12),
                  Text(
                    'No questions left to import',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Exam'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Top Summary Strip
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.rule_rounded,
                          color: Color(0xFF7C3AED),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_questions.length} Questions Ready',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.targetTotalMarks != null &&
                                      widget.targetTotalMarks! > 0
                                  ? 'Marks: ${_totalMarks.toInt()} / ${widget.targetTotalMarks!.toInt()} pts Target'
                                  : 'Total: ${_totalMarks.toInt()} Marks • $_validCount/${_questions.length} Validated',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.targetTotalMarks != null &&
                          widget.targetTotalMarks! > 0)
                        Builder(
                          builder: (context) {
                            final target = widget.targetTotalMarks!;
                            final isMatched = _totalMarks == target;
                            final diff = (target - _totalMarks).toInt();

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isMatched
                                    ? const Color(0xFF10B981).withOpacity(0.12)
                                    : (diff > 0
                                        ? const Color(0xFFF59E0B)
                                            .withOpacity(0.12)
                                        : const Color(0xFFEF4444)
                                            .withOpacity(0.12)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isMatched
                                        ? Icons.check_circle_outline
                                        : Icons.info_outline,
                                    size: 13,
                                    color: isMatched
                                        ? const Color(0xFF10B981)
                                        : (diff > 0
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFEF4444)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isMatched
                                        ? 'Marks Matched'
                                        : (diff > 0
                                            ? '$diff pts remaining'
                                            : '${-diff} pts over target'),
                                    style: TextStyle(
                                      color: isMatched
                                          ? const Color(0xFF10B981)
                                          : (diff > 0
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFFEF4444)),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 12,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Tap answer to change',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Scrollable Question List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: _questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final q = _questions[index];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Q number, Badges, Edit Marks & Delete
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Q${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    q.category,
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Marks button
                                GestureDetector(
                                  onTap: () => _editQuestionMarks(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${q.marks.toInt()} pt${q.marks > 1 ? "s" : ""}',
                                          style: const TextStyle(
                                            color: Color(0xFFF59E0B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        const Icon(
                                          Icons.edit_outlined,
                                          size: 11,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Delete question button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Remove Question',
                                  onPressed: () => _deleteQuestion(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Question Text
                            Text(
                              q.questionText,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Options List with 1-Tap Correct Option selection
                            ...q.options.map((opt) {
                              final isCorrect = opt.id == q.correctOptionId;

                              return GestureDetector(
                                onTap: () => _updateCorrectOption(index, opt.id),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCorrect
                                        ? const Color(0xFF10B981).withOpacity(isDarkMode ? 0.2 : 0.1)
                                        : (isDarkMode ? Colors.white.withOpacity(0.04) : Colors.grey.shade50),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isCorrect
                                          ? const Color(0xFF10B981)
                                          : (isDarkMode ? Colors.white12 : Colors.grey.shade200),
                                      width: isCorrect ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCorrect
                                              ? const Color(0xFF10B981)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isCorrect
                                                ? const Color(0xFF10B981)
                                                : (isDarkMode ? Colors.white38 : Colors.grey.shade400),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: isCorrect
                                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                                              : Text(
                                                  opt.id,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          opt.text,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isCorrect ? FontWeight.bold : FontWeight.w500,
                                            color: isCorrect
                                                ? (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF065F46))
                                                : textColor,
                                          ),
                                        ),
                                      ),
                                      if (isCorrect)
                                        const Text(
                                          'Correct',
                                          style: TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Sticky Action Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: Text(
                              'Import ${_questions.length} Questions',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.pop(context, _questions);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
