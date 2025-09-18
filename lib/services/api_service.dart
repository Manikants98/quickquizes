import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_models.dart';

class ApiService {
  // Use different URLs based on platform and environment
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:3000/api';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost directly
      return 'http://localhost:3000/api';
    } else {
      // Default fallback
      return 'http://localhost:3000/api';
    }
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static bool _interceptorAdded = false;

  static Future<void> _addAuthInterceptor() async {
    if (_interceptorAdded) return;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    _interceptorAdded = true;
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.post(
        '/auth/signin',
        data: {'email': email, 'password': password},
      );
      print("Login response received $response");
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.post(
        '/auth/signup',
        data: {'email': email, 'password': password, 'name': name},
      );
      if (response.statusCode == 201) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  static Future<List<QuizCategory>> getCategories() async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.get('/categories');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => QuizCategory.fromApi(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get categories error: $e');
      return [];
    }
  }

  static Future<List<Question>> getQuestionsByCategory(
    String categoryId,
  ) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.get(
        '/questions',
        queryParameters: {'categoryId': categoryId},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> questions = data['questions'];
        return questions.map((json) => Question.fromApi(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get questions error: $e');
      return [];
    }
  }

  static Future<String?> createQuizSession(
    String userId,
    String categoryId,
    int totalQuestions,
  ) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.post(
        '/quiz-sessions',
        data: {
          'userId': userId,
          'categoryId': categoryId,
          'totalQuestions': totalQuestions,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        return data['id'];
      }
      return null;
    } catch (e) {
      print('Create quiz session error: $e');
      return null;
    }
  }

  static Future<bool> updateQuizSession(
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.put(
        '/quiz-sessions/$sessionId',
        data: sessionData,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update quiz session error: $e');
      return false;
    }
  }

  // Scores
  static Future<bool> saveScore(
    String userId,
    String categoryId,
    int score,
    int totalQuestions,
    int timeSpent,
  ) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.post(
        '/scores',
        data: {
          'userId': userId,
          'categoryId': categoryId,
          'score': score,
          'totalQuestions': totalQuestions,
          'percentage': (score / totalQuestions) * 100,
          'timeSpent': timeSpent,
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Save score error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getScores(String userId) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.get(
        '/scores',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return List<Map<String, dynamic>>.from(data['scores']);
      }
      return [];
    } catch (e) {
      print('Get scores error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getBestScore(
    String userId,
    String categoryId,
  ) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.get(
        '/scores/best',
        queryParameters: {'userId': userId, 'categoryId': categoryId},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Get best score error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getOverallStats(String userId) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.get('/users/$userId/stats');

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      print('Get overall stats error: $e');
      return {};
    }
  }
}
