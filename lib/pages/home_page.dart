import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/quiz_models.dart';
import '../services/auth_service.dart';
import '../services/quiz_service.dart';
import '../widgets/skeleton_loader.dart';
import 'categories_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> overallStats = {};
  Map<String, Map<String, dynamic>> categoryStats = {};
  List<QuizCategory> categories = [];
  bool isLoading = true;
  bool _isDisposed = false;
  late AnimationController _animationController;
  String? userName;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      final loadedCategories = await QuizService.getCategories();
      final name = await AuthService.getUserName();

      final stats = await QuizService.getOverallStats();
      final catStats = <String, Map<String, dynamic>>{};

      for (final category in loadedCategories) {
        catStats[category.id] = await QuizService.getQuizStatus(category.id);
      }

      if (mounted && !_isDisposed) {
        setState(() {
          overallStats = stats;
          categoryStats = catStats;
          categories = loadedCategories;
          userName = name;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load statistics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: userName != null && userName!.isNotEmpty
                  ? Text(
                      userName![0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(Icons.person, size: 18, color: Theme.of(context).colorScheme.onPrimary),
            ),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: isLoading
          ? _buildSkeletonLoader()
          : (overallStats['totalQuizzesAttempted'] ?? 0) == 0
          ? _buildEmptyState()
          : _buildDashboard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to Quiz Dashboard!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Start taking quizzes to see your progress, statistics, and performance analytics here.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Categories()),
              ),
              icon: const Icon(Icons.quiz),
              label: const Text('Start Your First Quiz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _safeRefresh() async {
    if (!mounted || _isDisposed) return;
    try {
      await _loadStatistics();
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to refresh: $e')));
      }
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _safeRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 16),
            _buildScoreChart(),
            const SizedBox(height: 16),
            _buildCategoryProgressChart(),
            const SizedBox(height: 16),
            _buildPerformanceTrend(),
            const SizedBox(height: 16),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Quizzes',
                '${overallStats['totalQuizzesAttempted'] ?? 0}',
                Icons.quiz,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Average Score',
                '${(overallStats['averageScore'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Categories',
                '${overallStats['categoriesCompleted'] ?? 0}/${categories.length}',
                Icons.category,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Time Spent',
                '${overallStats['totalTimeSpent'] ?? 0}m',
                Icons.access_time,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChart() {
    if (_isDisposed || (overallStats['totalQuizzesAttempted'] ?? 0) == 0) {
      return const SizedBox.shrink();
    }

    // Skip if we're in the process of disposing
    if (!mounted) return const SizedBox.shrink();

    final correctAnswers = overallStats['totalCorrectAnswers'] ?? 0;
    final totalQuestions = overallStats['totalQuestionsAnswered'] ?? 1;
    final incorrectAnswers = totalQuestions - correctAnswers;

    final List<ChartData> chartData = [
      ChartData('Correct', correctAnswers.toDouble(), Colors.green),
      ChartData('Incorrect', incorrectAnswers.toDouble(), Colors.red),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Distribution',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.category,
                    yValueMapper: (ChartData data, _) => data.value,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                    dataLabelMapper: (ChartData data, _) =>
                        '${(data.value / totalQuestions * 100).round()}%',
                    innerRadius: '40%',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgressChart() {
    if (_isDisposed || categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    // Skip if we're in the process of disposing
    if (!mounted) return const SizedBox.shrink();

    final List<CategoryProgressData> chartData = [];

    for (final entry in categoryStats.entries) {
      final categoryId = entry.key;
      final stats = entry.value;
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => categories.isNotEmpty
            ? categories.first
            : QuizCategory(
                id: categoryId,
                name: 'Unknown',
                description: 'Unknown category',
                icon: Icons.help,
                color: Colors.grey,
                questions: [],
              ),
      );

      final percentage = stats['bestScorePercentage'] ?? 0;
      chartData.add(
        CategoryProgressData(
          category.name.length > 8
              ? '${category.name.substring(0, 8)}...'
              : category.name,
          percentage.toDouble(),
          category.color,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Progress',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(
                  labelRotation: -45,
                  labelIntersectAction: AxisLabelIntersectAction.rotate45,
                ),
                primaryYAxis: const NumericAxis(
                  minimum: 0,
                  maximum: 100,
                  interval: 25,
                  labelFormat: '{value}%',
                ),
                series: <CartesianSeries>[
                  ColumnSeries<CategoryProgressData, String>(
                    dataSource: chartData,
                    xValueMapper: (CategoryProgressData data, _) =>
                        data.category,
                    yValueMapper: (CategoryProgressData data, _) =>
                        data.percentage,
                    pointColorMapper: (CategoryProgressData data, _) =>
                        data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                    ),
                    dataLabelMapper: (CategoryProgressData data, _) =>
                        '${data.percentage.round()}%',
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to extract best score percentage from stats
  double _getBestScorePercentage(Map<String, dynamic> stats) {
    final bestScore = stats['bestScore'];
    if (bestScore is Map<String, dynamic>) {
      return (bestScore['percentage'] as num? ?? 0).toDouble();
    } else if (bestScore is num) {
      return bestScore.toDouble();
    }
    return 0.0;
  }

  Widget _buildPerformanceTrend() {
    if (_isDisposed || categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    // Skip if we're in the process of disposing
    if (!mounted) return const SizedBox.shrink();

    // Filter and sort categories by best score
    final sortedCategories =
        categories.where((category) {
          final stats = categoryStats[category.id];
          return stats != null && stats['bestScore'] != null;
        }).toList()..sort((a, b) {
          final statsA = categoryStats[a.id]!;
          final statsB = categoryStats[b.id]!;
          final scoreA = _getBestScorePercentage(statsA);
          final scoreB = _getBestScorePercentage(statsB);
          return scoreB.compareTo(scoreA); // Sort in descending order
        });

    // Take top 5 categories
    final topCategories = sortedCategories.take(5).toList();

    if (topCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Best Performing Categories',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...topCategories
                .map((category) {
                  final stats = categoryStats[category.id]!;
                  final percentage = _getBestScorePercentage(stats);
                  return _buildPerformanceItem(category, percentage);
                })
                .take(5),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(QuizCategory category, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/'),
                    icon: const Icon(Icons.quiz),
                    label: const Text('Take Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDetailedStats(),
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedStats() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Detailed Statistics',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                children: [
                  _buildStatCard(
                    'Total Quizzes Attempted',
                    '${overallStats['totalQuizzesAttempted'] ?? 0}',
                    Icons.quiz,
                    Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Categories Explored',
                    '${overallStats['categoriesCompleted'] ?? 0} / ${categories.length}',
                    Icons.category,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Average Score',
                    '${(overallStats['averageScore'] ?? 0.0).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Total Time Spent',
                    '${overallStats['totalTimeSpent'] ?? 0} minutes',
                    Icons.access_time,
                    Colors.orange,
                  ),
                  if (overallStats['bestCategory'] != null) ...[
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Best Category',
                      '${_getCategoryName(overallStats['bestCategory'])} (${(overallStats['bestCategoryAverage'] ?? 0.0).toStringAsFixed(1)}%)',
                      Icons.star,
                      Colors.amber,
                    ),
                  ],
                  if (overallStats['lastActivity'] != null) ...[
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Last Activity',
                      _formatDate(overallStats['lastActivity']),
                      Icons.schedule,
                      Colors.purple,
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    final category = categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : QuizCategory(
              id: categoryId,
              name: 'Unknown',
              description: 'Unknown category',
              icon: Icons.help,
              color: Colors.grey,
              questions: [],
            ),
    );
    return category.name;
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards skeleton
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SkeletonLoader(
                          width: 40,
                          height: 40,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        const SizedBox(height: 8),
                        const SkeletonText(width: 60, height: 24),
                        const SizedBox(height: 4),
                        const SkeletonText(width: 80, height: 14),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SkeletonLoader(
                          width: 40,
                          height: 40,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        const SizedBox(height: 8),
                        const SkeletonText(width: 60, height: 24),
                        const SizedBox(height: 4),
                        const SkeletonText(width: 80, height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Chart skeleton
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(width: 150, height: 18),
                  const SizedBox(height: 16),
                  SkeletonLoader(
                    width: double.infinity,
                    height: 200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Recent activities skeleton
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(width: 120, height: 18),
                  const SizedBox(height: 16),
                  ...List.generate(3, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SkeletonAvatar(size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonText(width: double.infinity, height: 14),
                              const SizedBox(height: 4),
                              SkeletonText(width: 100, height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateInput) {
    DateTime date;
    if (dateInput is DateTime) {
      date = dateInput;
    } else if (dateInput is String) {
      date = DateTime.parse(dateInput);
    } else {
      return 'Unknown';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Data classes for Syncfusion charts
class ChartData {
  ChartData(this.category, this.value, this.color);
  final String category;
  final double value;
  final Color color;
}

class CategoryProgressData {
  CategoryProgressData(this.category, this.percentage, this.color);
  final String category;
  final double percentage;
  final Color color;
}
