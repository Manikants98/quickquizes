import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_models.dart';

class StorageService {
  static const String _quizSessionKey = 'quiz_session_';
  static const String _scoresKey = 'quiz_scores';

  static Future<void> saveQuizSession(QuizSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _quizSessionKey + session.categoryId;
    await prefs.setString(key, jsonEncode(session.toJson()));
  }

  static Future<QuizSession?> getQuizSession(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _quizSessionKey + categoryId;
    final sessionData = prefs.getString(key);

    if (sessionData != null) {
      return QuizSession.fromJson(jsonDecode(sessionData));
    }
    return null;
  }

  static Future<void> clearQuizSession(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _quizSessionKey + categoryId;
    await prefs.remove(key);
  }

  static Future<void> saveScore(
    String categoryId,
    int score,
    int totalQuestions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = await getScores();

    final scoreData = {
      'categoryId': categoryId,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': (score / totalQuestions * 100).round(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    scores.add(scoreData);
    await prefs.setString(_scoresKey, jsonEncode(scores));
  }

  static Future<List<Map<String, dynamic>>> getScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresData = prefs.getString(_scoresKey);

    if (scoresData != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(scoresData));
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getBestScore(String categoryId) async {
    final scores = await getScores();
    final categoryScores = scores
        .where((score) => score['categoryId'] == categoryId)
        .toList();

    if (categoryScores.isEmpty) return null;

    categoryScores.sort((a, b) => b['percentage'].compareTo(a['percentage']));
    return categoryScores.first;
  }

  // Get quiz status for a specific category
  static Future<Map<String, dynamic>> getQuizStatus(String categoryId) async {
    final scores = await getScores();
    final categoryScores = scores.where((score) => score['categoryId'] == categoryId).toList();
    final hasActiveSession = await getQuizSession(categoryId) != null;
    final bestScore = await getBestScore(categoryId);
    
    return {
      'hasAttempted': categoryScores.isNotEmpty,
      'hasActiveSession': hasActiveSession,
      'totalAttempts': categoryScores.length,
      'bestScore': bestScore,
      'bestScorePercentage': bestScore?['percentage'] ?? 0,
      'lastAttemptDate': categoryScores.isNotEmpty 
          ? DateTime.fromMillisecondsSinceEpoch(categoryScores.last['timestamp'])
          : null,
      'averageScore': categoryScores.isNotEmpty
          ? categoryScores.map((s) => s['percentage'] as int).reduce((a, b) => a + b) / categoryScores.length
          : 0.0,
    };
  }

  // Get overall quiz statistics
  static Future<Map<String, dynamic>> getOverallStats() async {
    final allScores = await getScores();
    final uniqueCategories = allScores.map((s) => s['categoryId']).toSet();
    
    if (allScores.isEmpty) {
      return {
        'totalQuizzesAttempted': 0,
        'categoriesCompleted': 0,
        'totalCorrectAnswers': 0,
        'totalQuestionsAnswered': 0,
        'averageScore': 0.0,
        'bestCategory': null,
        'totalTimeSpent': 0,
        'lastActivity': null,
      };
    }
    
    final totalCorrect = allScores.map((s) => s['score'] as int).reduce((a, b) => a + b);
    final totalQuestions = allScores.map((s) => s['totalQuestions'] as int).reduce((a, b) => a + b);
    final averageScore = allScores.map((s) => s['percentage'] as int).reduce((a, b) => a + b) / allScores.length;
    
    // Find best performing category
    Map<String, List<int>> categoryPerformance = {};
    for (var score in allScores) {
      final categoryId = score['categoryId'] as String;
      categoryPerformance.putIfAbsent(categoryId, () => []).add(score['percentage'] as int);
    }
    
    String? bestCategoryId;
    double bestCategoryAverage = 0;
    for (var entry in categoryPerformance.entries) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (average > bestCategoryAverage) {
        bestCategoryAverage = average;
        bestCategoryId = entry.key;
      }
    }
    
    return {
      'totalQuizzesAttempted': allScores.length,
      'categoriesCompleted': uniqueCategories.length,
      'totalCorrectAnswers': totalCorrect,
      'totalQuestionsAnswered': totalQuestions,
      'averageScore': averageScore,
      'bestCategory': bestCategoryId,
      'bestCategoryAverage': bestCategoryAverage,
      'totalTimeSpent': allScores.length * 30, // Approximate 30 min per quiz
      'lastActivity': allScores.isNotEmpty 
          ? DateTime.fromMillisecondsSinceEpoch(allScores.last['timestamp'])
          : null,
    };
  }

  // Get quiz progress for all categories
  static Future<Map<String, Map<String, dynamic>>> getAllQuizStatuses(List<String> categoryIds) async {
    Map<String, Map<String, dynamic>> statuses = {};
    
    for (String categoryId in categoryIds) {
      statuses[categoryId] = await getQuizStatus(categoryId);
    }
    
    return statuses;
  }
}
