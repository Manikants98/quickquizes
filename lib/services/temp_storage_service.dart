import '../models/quiz_models.dart';

// Temporary in-memory storage service for testing without SharedPreferences
class TempStorageService {
  static final Map<String, QuizSession> _sessions = {};
  static final List<Map<String, dynamic>> _scores = [];

  static Future<void> saveQuizSession(QuizSession session) async {
    _sessions[session.categoryId] = session;
  }

  static Future<QuizSession?> getQuizSession(String categoryId) async {
    return _sessions[categoryId];
  }

  static Future<void> clearQuizSession(String categoryId) async {
    _sessions.remove(categoryId);
  }

  static Future<void> saveScore(String categoryId, int score, int totalQuestions) async {
    final scoreData = {
      'categoryId': categoryId,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': (score / totalQuestions * 100).round(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _scores.add(scoreData);
  }

  static Future<List<Map<String, dynamic>>> getScores() async {
    return List.from(_scores);
  }

  static Future<Map<String, dynamic>?> getBestScore(String categoryId) async {
    final categoryScores = _scores.where((score) => score['categoryId'] == categoryId).toList();
    
    if (categoryScores.isEmpty) return null;
    
    categoryScores.sort((a, b) => b['percentage'].compareTo(a['percentage']));
    return categoryScores.first;
  }

  // Get quiz status for a specific category
  static Future<Map<String, dynamic>> getQuizStatus(String categoryId) async {
    final categoryScores = _scores.where((score) => score['categoryId'] == categoryId).toList();
    final hasActiveSession = _sessions.containsKey(categoryId);
    final bestScore = await getBestScore(categoryId);
    
    return {
      'hasAttempted': categoryScores.isNotEmpty,
      'hasActiveSession': hasActiveSession,
      'totalAttempts': categoryScores.length,
      'bestScore': bestScore,
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
        'averageScore': 0.0,
        'bestCategory': null,
        'totalTimeSpent': 0,
        'lastActivity': null,
      };
    }
    
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
      'averageScore': averageScore,
      'bestCategory': bestCategoryId,
      'bestCategoryAverage': bestCategoryAverage,
      'totalTimeSpent': allScores.length * 30, // Approximate 30 min per quiz
      'lastActivity': DateTime.fromMillisecondsSinceEpoch(allScores.last['timestamp']),
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
