import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> overallStats = {};
  Map<String, Map<String, dynamic>> categoryStats = {};
  List<QuizCategory> categories = [];
  List<Achievement> achievements = [];
  bool isLoading = true;
  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      // Load user info
      userName = await AuthService.getUserName();
      userEmail = await AuthService.getUserEmail();

      // Load statistics
      final stats = await QuizService.getOverallStats();
      final loadedCategories = await QuizService.getCategories();
      final catStats = <String, Map<String, dynamic>>{};

      for (final category in loadedCategories) {
        catStats[category.id] = await QuizService.getQuizStatus(category.id);
      }

      // Calculate achievements
      final calculatedAchievements = _calculateAchievements(stats, catStats);

      if (mounted) {
        setState(() {
          overallStats = stats;
          categories = loadedCategories;
          categoryStats = catStats;
          achievements = calculatedAchievements;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data: $e')),
        );
      }
    }
  }

  List<Achievement> _calculateAchievements(
    Map<String, dynamic> stats,
    Map<String, Map<String, dynamic>> catStats,
  ) {
    final List<Achievement> achievements = [];
    final totalQuizzes = stats['totalQuizzesAttempted'] ?? 0;
    final averageScore = stats['averageScore'] ?? 0.0;
    final categoriesCompleted = stats['categoriesCompleted'] ?? 0;

    // First Quiz Achievement
    if (totalQuizzes >= 1) {
      achievements.add(
        Achievement(
          id: 'first_quiz',
          title: 'First Steps',
          description: 'Completed your first quiz',
          icon: Icons.play_arrow,
          color: Colors.green,
          isUnlocked: true,
        ),
      );
    }

    // Quiz Master Achievements
    if (totalQuizzes >= 10) {
      achievements.add(
        Achievement(
          id: 'quiz_master_10',
          title: 'Quiz Enthusiast',
          description: 'Completed 10 quizzes',
          icon: Icons.star,
          color: Colors.blue,
          isUnlocked: true,
        ),
      );
    }

    if (totalQuizzes >= 50) {
      achievements.add(
        Achievement(
          id: 'quiz_master_50',
          title: 'Quiz Master',
          description: 'Completed 50 quizzes',
          icon: Icons.emoji_events,
          color: Colors.orange,
          isUnlocked: true,
        ),
      );
    }

    // Perfect Score Achievement
    bool hasPerfectScore = catStats.values.any(
      (stat) => (stat['bestScorePercentage'] ?? 0.0) >= 100.0,
    );
    if (hasPerfectScore) {
      achievements.add(
        Achievement(
          id: 'perfect_score',
          title: 'Perfectionist',
          description: 'Achieved 100% in a quiz',
          icon: Icons.grade,
          color: Colors.amber,
          isUnlocked: true,
        ),
      );
    }

    // High Achiever
    if (averageScore >= 80.0) {
      achievements.add(
        Achievement(
          id: 'high_achiever',
          title: 'High Achiever',
          description: 'Maintained 80%+ average score',
          icon: Icons.trending_up,
          color: Colors.purple,
          isUnlocked: true,
        ),
      );
    }

    // Category Explorer
    if (categoriesCompleted >= 3) {
      achievements.add(
        Achievement(
          id: 'category_explorer',
          title: 'Category Explorer',
          description: 'Attempted quizzes in 3+ categories',
          icon: Icons.explore,
          color: Colors.teal,
          isUnlocked: true,
        ),
      );
    }

    return achievements;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoCard(),
                    const SizedBox(height: 16),
                    _buildStatsOverview(),
                    const SizedBox(height: 16),
                    _buildPerformanceChart(),
                    const SizedBox(height: 16),
                    _buildAchievements(),
                    const SizedBox(height: 16),
                    _buildCategoryBreakdown(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (userName?.isNotEmpty == true)
                    ? userName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail ?? 'user@example.com',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getUserLevelColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getUserLevel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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

  Widget _buildStatsOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
                    _formatTime(overallStats['totalTimeSpent'] ?? 0),
                    Icons.access_time,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    if (categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final chartData = categoryStats.entries
        .where((entry) => entry.value['isCompleted'] == true)
        .map((entry) {
          final categoryName = categories
              .firstWhere(
                (cat) => cat.id == entry.key,
                orElse: () => QuizCategory(
                  id: '',
                  name: 'Unknown',
                  description: '',
                  icon: Icons.quiz,
                  questions: [],
                  color: Colors.grey,
                ),
              )
              .name;
          return ChartData(
            categoryName,
            (entry.value['bestScorePercentage'] ?? 0.0).toDouble(),
          );
        })
        .toList();

    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance by Category',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  labelIntersectAction: AxisLabelIntersectAction.rotate45,
                ),
                primaryYAxis: NumericAxis(minimum: 0, maximum: 100),
                series: <CartesianSeries<ChartData, String>>[
                  ColumnSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.category,
                    yValueMapper: (ChartData data, _) => data.percentage,
                    color: Theme.of(context).colorScheme.primary,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
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

  Widget _buildAchievements() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (achievements.isEmpty)
              const Center(
                child: Text(
                  'No achievements yet. Keep taking quizzes!',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: achievements
                    .map((achievement) => _buildAchievementBadge(achievement))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.color
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            achievement.icon,
            color: achievement.isUnlocked ? achievement.color : Colors.grey,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: achievement.isUnlocked ? achievement.color : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Performance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...categories.map((category) {
              final stats = categoryStats[category.id] ?? {};
              return _buildCategoryPerformanceItem(category, stats);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPerformanceItem(
    QuizCategory category,
    Map<String, dynamic> stats,
  ) {
    final isCompleted = stats['isCompleted'] ?? false;
    final bestScore = stats['bestScore'] ?? 0;
    final totalAttempts = stats['totalAttempts'] ?? 0;
    final bestPercentage = stats['bestScorePercentage'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(category.icon, color: category.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (isCompleted) ...[
                  Text(
                    'Best: $bestScore questions (${bestPercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Attempts: $totalAttempts',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ] else ...[
                  Text(
                    'Not attempted yet',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPerformanceColor(bestPercentage),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getPerformanceLabel(bestPercentage),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getUserLevel() {
    final totalQuizzes = overallStats['totalQuizzesAttempted'] ?? 0;
    if (totalQuizzes >= 50) return 'Expert';
    if (totalQuizzes >= 20) return 'Advanced';
    if (totalQuizzes >= 10) return 'Intermediate';
    if (totalQuizzes >= 1) return 'Beginner';
    return 'New User';
  }

  Color _getUserLevelColor() {
    final level = _getUserLevel();
    switch (level) {
      case 'Expert':
        return Colors.purple;
      case 'Advanced':
        return Colors.orange;
      case 'Intermediate':
        return Colors.blue;
      case 'Beginner':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 50) return Colors.blue;
    return Colors.red;
  }

  String _getPerformanceLabel(double percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 70) return 'Good';
    if (percentage >= 50) return 'Average';
    return 'Needs Work';
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });
}

class ChartData {
  final String category;
  final double percentage;

  ChartData(this.category, this.percentage);
}
