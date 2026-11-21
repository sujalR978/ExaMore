import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/auth/screens/registration_screen.dart';

class OnboardingPageModel {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accentColor;

  const OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isNavigating = false;

  static const String prefKeyOnboardingCompleted = 'onboarding_completed';

  final List<OnboardingPageModel> _pages = const [
    OnboardingPageModel(
      title: "Master Your Exams",
      subtitle: "Smart Practice & Mock Tests",
      description:
          "Take timed chapter-wise quizzes, practice full-length mock exams, and build solid test-day confidence with curated questions.",
      icon: Icons.assignment_turned_in_rounded,
      accentColor: Color(0xFF7C3AED),
    ),
    OnboardingPageModel(
      title: "Actionable Insights",
      subtitle: "Real-time Score & Accuracy Analytics",
      description:
          "Track your progress with instant scorecards, detailed answer explanations, and historical performance breakdowns over time.",
      icon: Icons.insights_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    OnboardingPageModel(
      title: "Classroom Cohorts",
      subtitle: "Connect with Instructors & Peers",
      description:
          "Join instructor-led classrooms with cohort codes, access teacher-curated exams, and elevate your learning together.",
      icon: Icons.groups_rounded,
      accentColor: Color(0xFF10B981),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboardingAndNavigate(Widget destination) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyOnboardingCompleted, true);
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => destination),
      (route) => false,
    );
  }

  void _onNextPressed() {
    if (_isNavigating) return;
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboardingAndNavigate(const Login());
    }
  }

  void _onPreviousPressed() {
    if (_isNavigating) return;
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.background(isDark);
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentPage > 0) {
          _onPreviousPressed();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Indicator
                    Row(
                      children: [
                        Image.asset(
                          'assets/image/examore_logo.png',
                          height: 32,
                          width: 32,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.school_rounded,
                            size: 28,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "ExaMore",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),

                    // Skip action (hidden on last page)
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: _isNavigating
                            ? null
                            : () => _completeOnboardingAndNavigate(const Login()),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFA78BFA),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48, height: 36),
                  ],
                ),
              ),

              // PageView content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // Visual Illustration Container
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: page.accentColor.withValues(alpha: 0.12),
                              border: Border.all(
                                color: page.accentColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: page.accentColor.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                page.icon,
                                size: 100,
                                color: page.accentColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Badge / Subtitle pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: page.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: page.accentColor.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              page.subtitle,
                              style: TextStyle(
                                color: page.accentColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Main Title
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Description
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: textSecondary,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Section: Indicators & Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page Indicator Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final bool isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // Navigation Action Buttons
                    Row(
                      children: [
                        // Previous Button (disabled/hidden on page 0)
                        if (_currentPage > 0)
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: _isNavigating ? null : _onPreviousPressed,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Back",
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),

                        if (_currentPage > 0) const SizedBox(width: 12),

                        // Next or Get Started Button
                        Expanded(
                          flex: _currentPage > 0 ? 2 : 1,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7C3AED),
                                  Color(0xFF6D28D9),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _isNavigating ? null : _onNextPressed,
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: _isNavigating
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _currentPage == _pages.length - 1
                                                  ? "GET STARTED"
                                                  : "NEXT",
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              _currentPage == _pages.length - 1
                                                  ? Icons.check_circle_outline_rounded
                                                  : Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Additional Login / Register link on last page
                    if (_currentPage == _pages.length - 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "New to ExaMore? ",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isNavigating
                                ? null
                                : () => _completeOnboardingAndNavigate(
                                      const Registration(),
                                    ),
                            child: const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA78BFA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
