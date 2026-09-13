import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';

class CandidateDetailScreen extends StatefulWidget {
  const CandidateDetailScreen({super.key});

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  Color? get textColor => null;

  void _handleBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffold = GlobalKey<ScaffoldState>();
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
      key: _scaffold,
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
                        _scaffold.currentState?.openDrawer();
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
            // Back to Candidates link
            InkWell(
              onTap: _handleBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back,
                    size: 16,
                    color: isDarkMode
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF1E1B4B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Back to Candidates',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Top Profile Card
            Container(
              padding: const EdgeInsets.all(22),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with Online Badge
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 36,
                            backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: containerColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ID Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ID: EXM-2026-9812',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? const Color(0xFF93C5FD)
                                      : const Color(0xFF3730A3),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Jane Doe',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 14,
                                  color: subtitleColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Advanced Calculus - Mock A',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 20),

                  // Overall Score Section
                  Text(
                    'OVERALL SCORE',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '92',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '%',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF064E3B)
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF059669),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Passed',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Performance Summary Section Card
            Container(
              padding: const EdgeInsets.all(22),
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
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Performance Summary',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Total Marks Row
                  _buildSummaryRow(
                    icon: Icons.functions,
                    iconBg: isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF1D4ED8),
                    title: 'Total Marks',
                    value: '92 / 100',
                    valueColor: textColor,
                    containerColor: containerColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 14),

                  // Correct Answers Row
                  _buildSummaryRow(
                    icon: Icons.check,
                    iconBg: isDarkMode
                        ? const Color(0xFF064E3B)
                        : const Color(0xFFD1FAE5),
                    iconColor: const Color(0xFF059669),
                    title: 'Correct Answers',
                    value: '46',
                    valueColor: const Color(0xFF059669),
                    containerColor: containerColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 14),

                  // Incorrect Answers Row
                  _buildSummaryRow(
                    icon: Icons.close,
                    iconBg: isDarkMode
                        ? const Color(0xFF451A03)
                        : const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFDC2626),
                    title: 'Incorrect Answers',
                    value: '3',
                    valueColor: const Color(0xFFDC2626),
                    containerColor: containerColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 14),

                  // Unattempted Row
                  _buildSummaryRow(
                    icon: Icons.remove,
                    iconBg: isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    iconColor: subtitleColor,
                    title: 'Unattempted',
                    value: '1',
                    valueColor: textColor,
                    containerColor: containerColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
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

  Widget _buildSummaryRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
    required Color containerColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
