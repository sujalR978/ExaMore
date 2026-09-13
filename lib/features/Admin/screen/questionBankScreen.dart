import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/screen/AddMultipleChoiceQuestionScreen.dart';
import 'package:prep_mate/features/Admin/screen/ExamConfigurationScreen.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _Scaffold = GlobalKey<ScaffoldState>();

  final List<String> _categories = [
    'All Subjects',
    'Mathematics',
    'Science',
    'History',
    'Literature',
  ];

  // Track checked state of individual question cards
  final List<bool> _checkedStatus = [false, false, true, false];

  void _handleCreateExam() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ExamConfigurationScreen()));
  }

  void _handleAddQuestion() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMultipleChoiceQuestionScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      key: _Scaffold,
      drawer: const AdminMenuDrawer(),
      // Capsule-shaped Top Bar
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
                        _Scaffold.currentState?.openDrawer();
                      },
                    ),
                  ],
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
                    onPressed: _handleCreateExam,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
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
                          'Create Exam',
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
                      backgroundColor: const Color(
                        0xFFFBBF24,
                      ), // Amber CTA button
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
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
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
                      hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: subtitleColor),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

            // Question Card 1
            _buildQuestionCard(
              index: 0,
              subject: 'Mathematics',
              questionType: 'Multiple Choice',
              difficulty: 'Hard',
              questionText:
                  'Solve for x in the equation: 2x^2 + 5x - 3 = 0. Provide the complete derivation steps.',
              views: '142',
              timeAgo: '2d ago',
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),

            // Question Card 2
            _buildQuestionCard(
              index: 1,
              subject: 'Science',
              questionType: 'Short Answer',
              difficulty: 'Easy',
              questionText:
                  'Explain the process of photosynthesis in green plants and its role in the global carbon cycle.',
              views: '89',
              timeAgo: '5d ago',
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),

            // Question Card 3 (Selected state with highlighted border)
            _buildQuestionCard(
              index: 2,
              subject: 'History',
              questionType: 'Essay',
              difficulty: 'Medium',
              questionText:
                  'Discuss the socio-economic impact of the Industrial Revolution on European society.',
              views: '215',
              timeAgo: '1w ago',
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
              isHighlighted: true,
            ),
            const SizedBox(height: 16),

            // Question Card 4
            _buildQuestionCard(
              index: 3,
              subject: 'Literature',
              questionType: 'Multiple Choice',
              difficulty: 'Medium',
              questionText:
                  "Which central theme is most prominently explored in George Orwell's '1984'?",
              views: '304',
              timeAgo: '2w ago',
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),

            // Pagination Footer Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPaginationButton(
                  Icons.chevron_left,
                  () {},
                  containerColor,
                  textColor,
                  borderColor,
                  isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildPaginationNumber(
                  '1',
                  true,
                  containerColor,
                  textColor,
                  isDarkMode,
                ),
                const SizedBox(width: 6),
                _buildPaginationNumber(
                  '2',
                  false,
                  containerColor,
                  textColor,
                  isDarkMode,
                ),
                const SizedBox(width: 6),
                _buildPaginationNumber(
                  '3',
                  false,
                  containerColor,
                  textColor,
                  isDarkMode,
                ),
                const SizedBox(width: 6),
                Text(
                  '...',
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                _buildPaginationButton(
                  Icons.chevron_right,
                  () {},
                  containerColor,
                  textColor,
                  borderColor,
                  isDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required int index,
    required String subject,
    required String questionType,
    required String difficulty,
    required String questionText,
    required String views,
    required String timeAgo,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    bool isHighlighted = false,
  }) {
    final isChecked = _checkedStatus[index];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted || isChecked
              ? const Color(0xFF7C3AED)
              : borderColor,
          width: isHighlighted || isChecked ? 1.5 : 1.0,
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
              // Subject & Type Badges Row
              Wrap(
                spacing: 6,
                children: [
                  _buildBadge(
                    subject.toUpperCase(),
                    isDarkMode
                        ? const Color(0xFF312E81)
                        : const Color(0xFFDBEAFE),
                    isDarkMode
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF1D4ED8),
                  ),
                  _buildBadge(
                    questionType.toUpperCase(),
                    isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    subtitleColor,
                  ),
                  _buildBadge(
                    difficulty.toUpperCase(),
                    isDarkMode
                        ? const Color(0xFF451A03)
                        : const Color(0xFFFEF3C7),
                    const Color(0xFFB45309),
                  ),
                ],
              ),
              // Checkbox Toggle
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isChecked,
                  activeColor: const Color(0xFF1E1B4B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _checkedStatus[index] = val ?? false;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            questionText,
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
              Text(views, style: TextStyle(color: subtitleColor, fontSize: 12)),
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

  Widget _buildPaginationButton(
    IconData icon,
    VoidCallback onPressed,
    Color containerColor,
    Color textColor,
    Color borderColor,
    bool isDarkMode,
  ) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: textColor),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPaginationNumber(
    String number,
    bool isActive,
    Color containerColor,
    Color textColor,
    bool isDarkMode,
  ) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E1B4B) : containerColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            color: isActive ? const Color(0xFFFBBF24) : textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
