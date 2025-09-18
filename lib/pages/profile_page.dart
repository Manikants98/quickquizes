import 'package:aptitude_quiz/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../widgets/skeleton_loader.dart';
import 'auth_page.dart';
import 'settings_page.dart';

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
            icon: const Icon(Icons.palette_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              // Reload the app to apply theme changes
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                  (route) => false,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildProfileSkeleton()
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  return _buildAchievementBadge(achievements[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.color
              : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            achievement.icon,
            color: achievement.isUnlocked ? achievement.color : Colors.grey,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: achievement.isUnlocked ? achievement.color : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              achievement.description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Card(
      elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Performance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
    final bestPercentage = _getBestScorePercentage(stats);

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
            '${bestPercentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: category.color,
            ),
          ),
        ],
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
    final bestPercentage = stats['bestScorePercentage'];
    if (bestPercentage is num) {
      return bestPercentage.toDouble();
    }
    return 0.0;
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

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SkeletonAvatar(size: 60),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(width: 120, height: 20),
                        const SizedBox(height: 8),
                        SkeletonText(width: 180, height: 16),
                        const SizedBox(height: 8),
                        SkeletonText(width: 80, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats overview skeleton
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(width: 100, height: 18),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            SkeletonText(width: 40, height: 24),
                            const SizedBox(height: 4),
                            SkeletonText(width: 60, height: 14),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            SkeletonText(width: 40, height: 24),
                            const SizedBox(height: 4),
                            SkeletonText(width: 60, height: 14),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            SkeletonText(width: 40, height: 24),
                            const SizedBox(height: 4),
                            SkeletonText(width: 60, height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Performance chart skeleton
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(width: 140, height: 18),
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

          // Achievements skeleton
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(width: 100, height: 18),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SkeletonAvatar(size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SkeletonText(
                                      width: double.infinity,
                                      height: 12,
                                    ),
                                    const SizedBox(height: 4),
                                    SkeletonText(width: 60, height: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
