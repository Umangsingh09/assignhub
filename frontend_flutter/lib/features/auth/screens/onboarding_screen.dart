import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Notion-Simple Workspaces',
      description: 'Review and manage your class assignments in a clean, distraction-free environment. Easily browse instructions and resources.',
      emoji: '📚',
      accentColor: AppColors.primary,
      previewWidget: const SimpleWorkspacePreview(),
    ),
    OnboardingPageData(
      title: 'Cloud File Submissions',
      description: 'Upload files and PDFs directly to secure Supabase storage. Instantly register solutions and track late status checks.',
      emoji: '📤',
      accentColor: AppColors.secondary,
      previewWidget: const CloudStoragePreview(),
    ),
    OnboardingPageData(
      title: 'Linear-Fast Dashboard',
      description: 'Access full administrative statistics. Track late submissions, handle student approvals, and monitor operations with high-fidelity KPIs.',
      emoji: '⚡',
      accentColor: AppColors.accent,
      previewWidget: const AdminDashboardPreview(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top navigation header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AssignHub',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Centered Feature Live Preview Container
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _pages[index].previewWidget,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Text Content Area
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Dynamic Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: page.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: page.accentColor.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(page.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            'FEATURE ${ _currentPage + 1 }',
                            style: TextStyle(
                              color: page.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      page.title,
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      page.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Pagination Dots and Next Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: 300.ms,
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: isActive ? 20 : 6,
                        decoration: BoxDecoration(
                          color: isActive ? page.accentColor : AppColors.cardBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  
                  // Next / Get Started button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: 400.ms,
                          curve: Curves.easeInOutCubic,
                        );
                      } else {
                        context.go('/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: page.accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final String emoji;
  final Color accentColor;
  final Widget previewWidget;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.emoji,
    required this.accentColor,
    required this.previewWidget,
  });
}

// -------------------------------------------------------------
// DYNAMIC PREVIEW COMPONENT 1 (Simple Workspace Preview)
// -------------------------------------------------------------
class SimpleWorkspacePreview extends StatelessWidget {
  const SimpleWorkspacePreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
              ),
              const SizedBox(width: 6),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.warning),
              ),
              const SizedBox(width: 6),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '📝 Python Variables & Basics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(height: 1.5, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          const Text(
            'Write a Python program that calculates the area of a circle and verifies input bounds using conditionals.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 14, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text('guide.pdf', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Pending', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().scale(duration: 500.ms);
  }
}

// -------------------------------------------------------------
// DYNAMIC PREVIEW COMPONENT 2 (Cloud Storage Preview)
// -------------------------------------------------------------
class CloudStoragePreview extends StatelessWidget {
  const CloudStoragePreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.08),
            ),
            child: const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.secondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Uploading solution.zip...',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          // Loading Bar
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.76,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.secondary, AppColors.primary]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('76% uploaded', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text('1.2 MB/s', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          )
        ],
      ),
    ).animate().fade().scale(duration: 500.ms);
  }
}

// -------------------------------------------------------------
// DYNAMIC PREVIEW COMPONENT 3 (Admin Dashboard Preview)
// -------------------------------------------------------------
class AdminDashboardPreview extends StatelessWidget {
  const AdminDashboardPreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Operations Summary',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SUBMISSIONS', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('248', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COMPLETION', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('94.2%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Student Approval Row preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alice Johnson', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    SizedBox(height: 2),
                    Text('Roll: CS2026_014', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                      child: const Icon(Icons.close, size: 10, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade().scale(duration: 500.ms);
  }
}
