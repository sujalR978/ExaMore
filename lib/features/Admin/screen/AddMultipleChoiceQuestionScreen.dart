import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/screen/ReviewAndPublishScreen.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';


class AddMultipleChoiceQuestionScreen extends StatefulWidget {
  final ExamModel exam;
  final QuestionModel? editingQuestion;
  final int? questionIndex;
  final bool isForQuestionBank; 

  const AddMultipleChoiceQuestionScreen({
    super.key,
    required this.exam,
    this.editingQuestion,
    this.questionIndex,
    this.isForQuestionBank = false,
  });

  @override
  State<AddMultipleChoiceQuestionScreen> createState() =>
      _AddMultipleChoiceQuestionScreenState();
}

class _AddMultipleChoiceQuestionScreenState
    extends State<AddMultipleChoiceQuestionScreen> {
  final ExamService _examService = ExamService();

  late ExamModel _currentExam;
  late TextEditingController _questionController;
  late TextEditingController _marksController;
  late List<TextEditingController> _optionControllers;

  int _selectedCorrectOption = 0;
  bool _isLoading = false;

  bool get _isEditingQuestion => widget.editingQuestion != null;

  @override
  void initState() {
    super.initState();
    _currentExam = widget.exam;

    if (_isEditingQuestion) {
      final q = widget.editingQuestion!;
      _questionController = TextEditingController(text: q.questionText);
      _marksController = TextEditingController(
        text: q.marks.toInt().toString(),
      );

      _optionControllers = q.options
          .map((opt) => TextEditingController(text: opt.text))
          .toList();

      final correctIdx = q.options.indexWhere(
        (opt) => opt.id == q.correctOptionId,
      );
      _selectedCorrectOption = correctIdx >= 0 ? correctIdx : 0;
    } else {
      _questionController = TextEditingController();
      _marksController = TextEditingController(text: '1');
      _optionControllers = [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ];
      _selectedCorrectOption = 0;
    }
  }

  QuestionModel? _buildQuestionFromInputs() {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter question text'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }

    final validOptions = <QuestionOption>[];
    for (int i = 0; i < _optionControllers.length; i++) {
      final text = _optionControllers[i].text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter text for Option ${String.fromCharCode(65 + i)}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return null;
      }
      validOptions.add(
        QuestionOption(id: String.fromCharCode(65 + i), text: text),
      );
    }

    if (validOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 options are required'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }

    final marks = double.tryParse(_marksController.text.trim()) ?? 1.0;
    final selectedOptionLetter = String.fromCharCode(
      65 + _selectedCorrectOption,
    );

    return QuestionModel(
      id: _isEditingQuestion
          ? widget.editingQuestion!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      questionText: questionText,
      marks: marks,
      options: validOptions,
      correctOptionId: selectedOptionLetter,
      type: 'MULTIPLE_CHOICE',
      estimatedTimeMinutes: 2,
    );
  }

  Future<bool> _saveCurrentQuestionToFirebase(QuestionModel question) async {
    setState(() => _isLoading = true);

    try {
      // If adding directly into Question Bank collection
      if (widget.isForQuestionBank) {
        final bankQuestion = QuestionModel(
          id: question.id,
          questionText: question.questionText,
          marks: question.marks,
          options: question.options,
          correctOptionId: question.correctOptionId,
          type: question.type,
          category: _currentExam.category.isEmpty ? 'General' : _currentExam.category,
          difficulty: 'Medium',
          views: 0,
          estimatedTimeMinutes: question.estimatedTimeMinutes,
          createdAt: DateTime.now(),
        );

        await _examService.addQuestionToBank(bankQuestion);
        return true;
      }

      // Normal Exam workflow
      List<QuestionModel> updatedQuestions = List.from(_currentExam.questions);

      if (_isEditingQuestion && widget.questionIndex != null) {
        updatedQuestions[widget.questionIndex!] = question;
      } else {
        updatedQuestions.add(question);
      }

      final updatedExam = _currentExam.copyWith(
        questions: updatedQuestions,
        updatedAt: DateTime.now(),
      );

      await _examService.updateExam(updatedExam);
      _currentExam = updatedExam;
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving question: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  Future<void> _handleSaveAndAddAnother() async {
    final question = _buildQuestionFromInputs();
    if (question == null) return;

    final success = await _saveCurrentQuestionToFirebase(question);
    if (!success || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question saved successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );

    // Reset controllers for next question
    setState(() {
      _questionController.clear();
      _marksController.text = '1';
      for (var c in _optionControllers) {
        c.clear();
      }
      _selectedCorrectOption = 0;
    });
  }

  Future<void> _handleDone() async {
    if (_questionController.text.trim().isNotEmpty) {
      final question = _buildQuestionFromInputs();
      if (question == null) return;

      final success = await _saveCurrentQuestionToFirebase(question);
      if (!success || !mounted) return;
    }

    if (!mounted) return;

    if (widget.isForQuestionBank) {
      // Pop back to Question Bank screen
      Navigator.pop(context);
    } else {
      // Continue to review exam
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ReviewAndPublishScreen(exam: _currentExam),
        ),
      );
    }
  }

  void _handleAddOption() {
    if (_optionControllers.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 options allowed')),
      );
      return;
    }
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _handleRemoveOption(int index) {
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 2 options required')),
      );
      return;
    }
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      if (_selectedCorrectOption >= _optionControllers.length) {
        _selectedCorrectOption = _optionControllers.length - 1;
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _marksController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: _handleCancel,
                  ),
                  title: Text(
                    'Exam Administration',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Draft Auto-Saved Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditingQuestion
                            ? 'Edit Multiple Choice\nQuestion'
                            : 'Add Multiple Choice\nQuestion',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Configure the question text, options, and grading rules.',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Draft\nAuto-saved',
                        style: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF3730A3),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(24),
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
                  // Question Text Header & Marks Input Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '❞',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Question Text',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Marks:',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            height: 38,
                            child: TextFormField(
                              controller: _marksController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF7C3AED),
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Question Text Editor Box with Toolbar
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E293B).withOpacity(0.5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: borderColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildToolIcon(Icons.format_bold),
                              const SizedBox(width: 12),
                              _buildToolIcon(Icons.format_italic),
                              const SizedBox(width: 12),
                              _buildToolIcon(Icons.functions),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: Container(
                                  width: 1,
                                  height: 16,
                                  color: borderColor,
                                ),
                              ),
                              _buildToolIcon(Icons.image_outlined),
                            ],
                          ),
                        ),
                        TextField(
                          controller: _questionController,
                          maxLines: 4,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter your question here...',
                            hintStyle: TextStyle(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  DottedDivider(color: borderColor),
                  const SizedBox(height: 20),

                  // Answer Options Header
                  Row(
                    children: [
                      Icon(Icons.list, color: textColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Answer Options',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select the radio button next to the correct answer.',
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Options List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _optionControllers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCorrectOption == index;
                      final optionLabel = String.fromCharCode(65 + index);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : borderColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: _selectedCorrectOption,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCorrectOption = val!;
                                });
                              },
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFD1FAE5)
                                    : (isDarkMode
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFDBEAFE)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  optionLabel,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF065F46)
                                        : (isDarkMode
                                              ? const Color(0xFF93C5FD)
                                              : const Color(0xFF1D4ED8)),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _optionControllers[index],
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Option $optionLabel text...',
                                  hintStyle: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_optionControllers.length > 2)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _handleRemoveOption(index),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Add Another Option Button
                  TextButton.icon(
                    onPressed: _handleAddOption,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF7C3AED),
                      size: 20,
                    ),
                    label: const Text(
                      'Add another option',
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 20),

                  // Bottom Action Buttons (Cancel, Save & Add Another, Done)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(color: borderColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _handleSaveAndAddAnother,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E1B4B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Save & Add',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Another',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleDone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFBBF24),
                              foregroundColor: const Color(0xFF1E1B4B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF1E1B4B),
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Done',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildToolIcon(IconData icon) {
    return Icon(icon, size: 18, color: Colors.grey.shade600);
  }
}

class DottedDivider extends StatelessWidget {
  final Color color;

  const DottedDivider({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 1.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}
