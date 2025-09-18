import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class QuizService {
  static const String _sessionKey = 'current_quiz_session';

  // Get categories from API
  static Future<List<QuizCategory>> getCategories() async {
    return await ApiService.getCategories();
  }

  // Get questions for a category from API
  static Future<List<Question>> getQuestionsByCategory(
    String categoryId,
  ) async {
    return await ApiService.getQuestionsByCategory(categoryId);
  }

  // Quiz Session Management
  static Future<void> saveQuizSession(QuizSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, json.encode(session.toJson()));
  }

  static Future<QuizSession?> getQuizSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null) {
      return QuizSession.fromJson(json.decode(sessionJson));
    }
    return null;
  }

  static Future<void> clearQuizSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  // Save score to API and local storage
  static Future<void> saveScore(
    String categoryId,
    int score,
    int totalQuestions,
    int timeSpent,
  ) async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      await ApiService.saveScore(
        userId,
        categoryId,
        score,
        totalQuestions,
        timeSpent,
      );
    }

    // Also save locally for offline access
    final prefs = await SharedPreferences.getInstance();
    final scores = await getScores();
    scores.add({
      'categoryId': categoryId,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': (score / totalQuestions) * 100.0,
      'timeSpent': timeSpent,
      'date': DateTime.now().millisecondsSinceEpoch,
    });
    await prefs.setString('quiz_scores', json.encode(scores));
  }

  // Get scores from API or local storage
  static Future<List<Map<String, dynamic>>> getScores() async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      final apiScores = await ApiService.getScores(userId);
      if (apiScores.isNotEmpty) {
        return apiScores;
      }
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString('quiz_scores');
    if (scoresJson != null) {
      return List<Map<String, dynamic>>.from(json.decode(scoresJson));
    }
    return [];
  }

  // Get best score for a category
  static Future<Map<String, dynamic>?> getBestScore(String categoryId) async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      final bestScore = await ApiService.getBestScore(userId, categoryId);
      if (bestScore != null) {
        return bestScore;
      }
    }

    // Fallback to local calculation
    final scores = await getScores();
    final categoryScores = scores
        .where((s) => s['categoryId'] == categoryId)
        .toList();
    if (categoryScores.isEmpty) return null;

    categoryScores.sort((a, b) => b['score'].compareTo(a['score']));
    return categoryScores.first;
  }

  // Get quiz status for a category
  static Future<Map<String, dynamic>> getQuizStatus(String categoryId) async {
    try {
      final scores = await getScores();
      final categoryScores = scores
          .where((s) => s['categoryId'] == categoryId)
          .toList();

      if (categoryScores.isEmpty) {
        return {
          'isCompleted': false,
          'bestScore': 0,
          'bestScorePercentage': 0,
          'totalAttempts': 0,
          'averageScore': 0.0,
        };
      }

      final bestScore = categoryScores
          .map((s) => s['score'] as int? ?? 0)
          .reduce((a, b) => a > b ? a : b);
      final bestScorePercentage = categoryScores
          .map((s) => (s['percentage'] as num?)?.toDouble() ?? 0.0)
          .reduce((a, b) => a > b ? a : b);
      final totalAttempts = categoryScores.length;
      final averageScore =
          categoryScores
              .map((s) => s['score'] as int? ?? 0)
              .reduce((a, b) => a + b) /
          totalAttempts.toDouble();

      return {
        'isCompleted': true,
        'bestScore': bestScore,
        'bestScorePercentage': bestScorePercentage,
        'totalAttempts': totalAttempts,
        'averageScore': averageScore,
      };
    } catch (e) {
      print('Error getting quiz status: $e');
      return {
        'isCompleted': false,
        'bestScore': 0,
        'bestScorePercentage': 0,
        'totalAttempts': 0,
        'averageScore': 0.0,
      };
    }
  }

  // Get overall statistics
  static Future<Map<String, dynamic>> getOverallStats() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId != null) {
        final apiStats = await ApiService.getOverallStats(userId);
        if (apiStats.isNotEmpty) {
          return apiStats;
        }
      }
    } catch (e) {
      print('Failed to get stats from API: $e');
    }

    // Fallback to local calculation
    final scores = await getScores();
    if (scores.isEmpty) {
      return {
        'totalQuizzesAttempted': 0,
        'totalQuestionsAnswered': 0,
        'totalCorrectAnswers': 0,
        'averageScore': 0.0,
        'categoriesCompleted': 0,
        'totalTimeSpent': 0,
        'bestCategory': null,
        'bestCategoryAverage': 0.0,
        'lastActivity': null,
      };
    }

    final totalQuizzesAttempted = scores.length;
    final totalQuestionsAnswered = scores.fold<int>(
      0,
      (sum, s) => sum + (s['totalQuestions'] as int? ?? 0),
    );
    final totalCorrectAnswers = scores.fold<int>(
      0,
      (sum, s) => sum + (s['score'] as int? ?? 0),
    );
    final averageScore = totalQuestionsAnswered > 0
        ? (totalCorrectAnswers / totalQuestionsAnswered) * 100
        : 0.0;
    final totalTimeSpent = scores.fold<int>(
      0,
      (sum, s) => sum + (s['timeSpent'] as int? ?? 0),
    );
    final categoriesCompleted = scores
        .map((s) => s['categoryId'])
        .toSet()
        .length;

    return {
      'totalQuizzesAttempted': totalQuizzesAttempted,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrectAnswers': totalCorrectAnswers,
      'averageScore': averageScore,
      'categoriesCompleted': categoriesCompleted,
      'totalTimeSpent': totalTimeSpent,
      'bestCategory': null,
      'bestCategoryAverage': 0.0,
      'lastActivity': null,
    };
  }

  // Get all quiz statuses
  static Future<Map<String, Map<String, dynamic>>> getAllQuizStatuses() async {
    final categories = await getCategories();
    final Map<String, Map<String, dynamic>> statuses = {};

    for (final category in categories) {
      statuses[category.id] = await getQuizStatus(category.id);
    }

    return statuses;
  }
}
