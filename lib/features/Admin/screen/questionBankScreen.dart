import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/screen/AddMultipleChoiceQuestionScreen.dart';
import 'package:prep_mate/features/Admin/screen/ExamConfigurationScreen.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ExamService _examService = ExamService();

  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  final Set<String> _selectedQuestionIds = {};
  bool _isCreatingExam = false;

  final List<String> _categories = [
    'All Subjects',
    'Mathematics',
    'Science',
    'History',
    'Literature',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // Opens Add Question screen with a fallback ExamModel
  void _handleAddQuestion() {
    final currentCategory =
        _categories[_selectedCategoryIndex] == 'All Subjects'
        ? 'General'
        : _categories[_selectedCategoryIndex];

    final tempExam = ExamModel(
      id: '',
      examCode: '',
      title: 'Question Bank Entry',
      category: currentCategory,
      durationMinutes: 60,
      totalMarks: 100,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMultipleChoiceQuestionScreen(
          exam: tempExam,
          isForQuestionBank:
              true, // <-- Tell the screen to save into question_bank
        ),
      ),
    );
  }

  // Create an exam from selected bank questions or start blank
  Future<void> _handleCreateExam(List<QuestionModel> allQuestions) async {
    if (_selectedQuestionIds.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ExamConfigurationScreen(),
        ),
      );
      return;
    }

    setState(() => _isCreatingExam = true);

    try {
      final selectedQuestions = allQuestions
          .where((q) => _selectedQuestionIds.contains(q.id))
          .toList();

      final category = _selectedCategoryIndex == 0
          ? 'General'
          : _categories[_selectedCategoryIndex];

      final examId = await _examService.createExamWithQuestions(
        title: '$category Assessment Draft',
        category: category,
        questions: selectedQuestions,
      );

      final stream = _examService.getExamStream(examId);
      final newExam = await stream.first;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Created exam draft with ${selectedQuestions.length} questions!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ExamConfigurationScreen(exam: newExam),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create exam: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreatingExam = false);
    }
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

    final selectedCategory = _selectedCategoryIndex == 0
        ? null
        : _categories[_selectedCategoryIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      key: _scaffoldKey,
      drawer: const AdminMenuDrawer(),
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
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book,
                          color: isDarkMode
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF1E1B4B),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    'Examora',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  centerTitle: false,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.menu, color: textColor),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<QuestionModel>>(
        stream: _examService.getQuestionBankStream(category: selectedCategory),
        builder: (context, snapshot) {
          final allQuestions = snapshot.data ?? [];

          final filteredQuestions = allQuestions.where((q) {
            return q.questionText.toLowerCase().contains(_searchQuery) ||
                q.category.toLowerCase().contains(_searchQuery) ||
                q.difficulty.toLowerCase().contains(_searchQuery);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Question Bank',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and curate your repository of academic questions.',
                  style: TextStyle(color: subtitleColor, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Top Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isCreatingExam
                            ? null
                            : () => _handleCreateExam(allQuestions),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: borderColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isCreatingExam
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 18,
                                    color: isDarkMode
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFF1E1B4B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedQuestionIds.isNotEmpty
                                        ? 'Create (${_selectedQuestionIds.length})'
                                        : 'Create Exam',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleAddQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBBF24),
                          foregroundColor: const Color(0xFF1E1B4B),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Add Question',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar & Filter Chips Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDarkMode ? 0.2 : 0.02,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search questions...",
                          hintStyle: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(Icons.search, color: subtitleColor),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: subtitleColor,
                                    size: 18,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: isDarkMode
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF7C3AED),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final isSelected = _selectedCategoryIndex == index;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(_categories[index]),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategoryIndex = index;
                                  });
                                },
                                selectedColor: const Color(0xFF1E1B4B),
                                backgroundColor: isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDarkMode
                                            ? Colors.white70
                                            : const Color(0xFF1E1B4B)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.transparent
                                        : borderColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Question Cards
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filteredQuestions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        allQuestions.isEmpty
                            ? 'No questions in Question Bank yet. Tap "Add Question" to start!'
                            : 'No questions match "$_searchQuery"',
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredQuestions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final question = filteredQuestions[index];
                      final isChecked = _selectedQuestionIds.contains(
                        question.id,
                      );

                      return _buildQuestionCard(
                        question: question,
                        isChecked: isChecked,
                        timeAgo: _formatTimeAgo(question.createdAt),
                        containerColor: containerColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                        onCheckChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedQuestionIds.add(question.id);
                            } else {
                              _selectedQuestionIds.remove(question.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard({
    required QuestionModel question,
    required bool isChecked,
    required String timeAgo,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    required ValueChanged<bool?> onCheckChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isChecked ? const Color(0xFF7C3AED) : borderColor,
          width: isChecked ? 1.5 : 1.0,
        ),
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
              // Badges
              Wrap(
                spacing: 6,
                children: [
                  _buildBadge(
                    question.category.toUpperCase(),
                    isDarkMode
                        ? const Color(0xFF312E81)
                        : const Color(0xFFDBEAFE),
                    isDarkMode
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF1D4ED8),
                  ),
                  _buildBadge(
                    question.type.toUpperCase(),
                    isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    subtitleColor,
                  ),
                  _buildBadge(
                    question.difficulty.toUpperCase(),
                    isDarkMode
                        ? const Color(0xFF451A03)
                        : const Color(0xFFFEF3C7),
                    const Color(0xFFB45309),
                  ),
                ],
              ),
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isChecked,
                  activeColor: const Color(0xFF1E1B4B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: onCheckChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question.questionText,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 15, color: subtitleColor),
              const SizedBox(width: 4),
              Text(
                '${question.views}',
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 15, color: subtitleColor),
              const SizedBox(width: 4),
              Text(
                timeAgo,
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
