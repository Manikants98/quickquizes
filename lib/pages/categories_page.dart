import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loader.dart';
import 'quiz_detail_page.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  List<QuizCategory> categories = [];
  Map<String, Map<String, dynamic>> categoryStats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    if (!isLoading) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final loadedCategories = await ApiService.getCategories();
      final stats = <String, Map<String, dynamic>>{};

      for (final category in loadedCategories) {
        // Get both local and backend stats
        final localStats = await QuizService.getQuizStatus(category.id);
        try {
          final backendScores = await ApiService.getUserScores(category.id);
          final hasBackendAttempts = backendScores.isNotEmpty;
          
          // Merge local and backend data
          stats[category.id] = {
            ...localStats,
            'hasAttempted': localStats['hasAttempted'] || hasBackendAttempts,
            'totalAttempts': (localStats['totalAttempts'] as int) + backendScores.length,
            'backendAttempts': backendScores.length,
          };
        } catch (e) {
          print('Failed to get backend scores for ${category.id}: $e');
          stats[category.id] = localStats;
        }
      }

      if (mounted) {
        setState(() {
          categories = loadedCategories;
          categoryStats = stats;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Categories'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? _buildCategoriesSkeleton()
          : categories.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No categories available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final stats = categoryStats[category.id] ?? {};
                  return _buildCategoryCard(category, stats);
                },
              ),
            ),
    );
  }

  Widget _buildCategoryCard(QuizCategory category, Map<String, dynamic> stats) {
    final bestScore = stats['bestScore'] as int? ?? 0;
    final totalQuestions = stats['totalQuestions'] as int? ?? 0;
    final hasAttempted = stats['hasAttempted'] as bool? ?? false;
    final percentage = totalQuestions > 0
        ? (bestScore / totalQuestions * 100).round()
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizDetailPage(category: category),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, size: 30, color: category.color),
              ),
              const SizedBox(width: 16),

              // Category Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Quiz Info
                    Row(
                      children: [
                        Icon(Icons.quiz, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${category.questionCount ?? 0} questions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (category.timeLimit != null) ...[
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${category.timeLimit} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    if (hasAttempted) ...[
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Best: $bestScore/$totalQuestions ($percentage%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Not attempted yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow Icon
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Icon Skeleton
                SkeletonAvatar(size: 60),
                const SizedBox(width: 16),

                // Category Info Skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title skeleton
                      SkeletonText(width: 150, height: 18),
                      const SizedBox(height: 4),
                      
                      // Description skeleton
                      SkeletonText(width: double.infinity, height: 14),
                      const SizedBox(height: 2),
                      SkeletonText(width: 200, height: 14),
                      const SizedBox(height: 8),

                      // Quiz info row skeleton
                      Row(
                        children: [
                          SkeletonAvatar(size: 16),
                          const SizedBox(width: 4),
                          SkeletonText(width: 80, height: 12),
                          const SizedBox(width: 12),
                          SkeletonAvatar(size: 16),
                          const SizedBox(width: 4),
                          SkeletonText(width: 50, height: 12),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Best score row skeleton (sometimes visible)
                      if (index % 3 == 0) ...[
                        Row(
                          children: [
                            SkeletonAvatar(size: 16),
                            const SizedBox(width: 4),
                            SkeletonText(width: 60, height: 12),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
