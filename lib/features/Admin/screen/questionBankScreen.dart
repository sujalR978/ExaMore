import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/screen/AddMultipleChoiceQuestionScreen.dart';
import 'package:prep_mate/features/Admin/screen/ExamConfigurationScreen.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';
import 'package:prep_mate/features/Admin/services/question_file_parser.dart';

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
  bool _isImporting = false;

  final List<String> _categories = [
    'All Subjects',
    'Mathematics',
    'Science',
    'History',
    'Literature',
  ];

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

  // Bulk Import Questions from CSV/JSON
  Future<void> _handleBulkImport() async {
    try {
      final questions = await QuestionFileParser.pickAndParseQuestions();
      if (questions.isEmpty) return;

      if (!mounted) return;
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirm Bulk Import'),
          content: Text(
            'Found ${questions.length} questions in file. Upload them to Question Bank now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF1E1B4B),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import All'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _isImporting = true);

      // Batch insert into question_bank
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('question_bank');

      for (final q in questions) {
        final docRef = collection.doc();
        batch.set(docRef, {
          'id': docRef.id,
          'questionText': q.questionText,
          'marks': q.marks,
          'options': q.options.map((o) => o.toMap()).toList(), // ✅ Proper serialization
          'correctOptionId': q.correctOptionId,
          'type': q.type,
          'category': q.category,
          'difficulty': q.difficulty,
          'views': 0,
          'estimatedTimeMinutes': q.estimatedTimeMinutes,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported ${questions.length} questions!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // Opens Add Question screen with fallback ExamModel
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
          isForQuestionBank: true,
        ),
      ),
    );
  }

  // Delete a single question from Firestore Question Bank
  Future<void> _handleDeleteQuestion(String questionId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Question',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to remove this question from the bank?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('question_bank')
          .doc(questionId)
          .delete();
      setState(() => _selectedQuestionIds.remove(questionId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question deleted from Question Bank.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  // Show detailed view of options & correct answer
  void _showQuestionDetails(QuestionModel question) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          question.questionText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  _buildBadge(
                    question.category.toUpperCase(),
                    const Color(0xFFDBEAFE),
                    const Color(0xFF1D4ED8),
                  ),
                  _buildBadge(
                    '${question.marks} Marks',
                    const Color(0xFFDCFCE7),
                    const Color(0xFF15803D),
                  ),
                  _buildBadge(
                    question.difficulty.toUpperCase(),
                    const Color(0xFFFEF3C7),
                    const Color(0xFFB45309),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Options:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...question.options.map((opt) {
                final isCorrect = opt == question.correctOptionId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect ? Colors.green : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isCorrect ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          opt.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCorrect
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCorrect
                                ? const Color(0xFF14532D)
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Create an exam from selected bank questions
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
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
            if (_searchQuery.isEmpty) return true;
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

                // Top Action Buttons (Create Exam, Import CSV/JSON, Add Single)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
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
                                    Icons.assignment_turned_in_outlined,
                                    size: 18,
                                    color: isDarkMode
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFF1E1B4B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedQuestionIds.isNotEmpty
                                        ? 'Draft (${_selectedQuestionIds.length})'
                                        : 'Create Exam',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bulk Import Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: _isImporting ? null : _handleBulkImport,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: borderColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isImporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.file_upload_outlined, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    'Import File',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add Single Question Button
                    Expanded(
                      flex: 2,
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
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search questions by text or topic...",
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
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
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
                                  setState(
                                    () => _selectedCategoryIndex = index,
                                  );
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
                const SizedBox(height: 16),

                // Select All / Deselect All Bar
                if (filteredQuestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${filteredQuestions.length} Questions',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedQuestionIds.length ==
                                  filteredQuestions.length) {
                                _selectedQuestionIds.clear();
                              } else {
                                _selectedQuestionIds.addAll(
                                  filteredQuestions.map((q) => q.id),
                                );
                              }
                            });
                          },
                          child: Text(
                            _selectedQuestionIds.length ==
                                    filteredQuestions.length
                                ? 'Deselect All'
                                : 'Select All',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Question Cards List
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
                            ? 'No questions in Question Bank yet. Tap "Add" or "Import File" to start!'
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
                        const SizedBox(height: 14),
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
                        onTap: () => _showQuestionDetails(question),
                        onDelete: () => _handleDeleteQuestion(question.id),
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
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required ValueChanged<bool?> onCheckChanged,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
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
                      '${question.marks} MARKS',
                      isDarkMode
                          ? const Color(0xFF064E3B)
                          : const Color(0xFFDCFCE7),
                      isDarkMode
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF15803D),
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
                // Checkbox & Delete Action
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Delete Question',
                    ),
                    Checkbox(
                      value: isChecked,
                      activeColor: const Color(0xFF1E1B4B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onChanged: onCheckChanged,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.questionText,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.list_alt, size: 15, color: subtitleColor),
                const SizedBox(width: 4),
                Text(
                  '${question.options.length} options',
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 15, color: subtitleColor),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'Tap to preview',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
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
