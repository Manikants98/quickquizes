import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_models.dart';

class ApiService {
  // Use different URLs based on platform and environment
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:3001/api/v1';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost directly
      return 'http://localhost:3001/api/v1';
    } else {
      // Default fallback
      return 'http://localhost:3001/api/v1';
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

          // Log request details
          print('🚀 API REQUEST:');
          print('Method: ${options.method}');
          print('URL: ${options.baseUrl}${options.path}');
          print('Headers: ${options.headers}');
          if (options.queryParameters.isNotEmpty) {
            print('Query Parameters: ${options.queryParameters}');
          }
          if (options.data != null) {
            print('Request Payload: ${options.data}');
          }
          print('---');

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response details
          print('✅ API RESPONSE:');
          print('Status Code: ${response.statusCode}');
          print(
            'URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}',
          );
          print('Response Data: ${response.data}');
          print('---');

          handler.next(response);
        },
        onError: (error, handler) {
          // Log error details
          print('❌ API ERROR:');
          print('Status Code: ${error.response?.statusCode}');
          print(
            'URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}',
          );
          print('Error Message: ${error.message}');
          if (error.response?.data != null) {
            print('Error Response: ${error.response?.data}');
          }
          print('---');

          handler.next(error);
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
        '/auth/login',
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
        '/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );
      if (response.statusCode == 200) {
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
      final response = await _dio.get('/quizzes');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> quizzes = data['quizzes'] ?? [];

        return quizzes
            .map(
              (quiz) => QuizCategory.fromApi({
                'id': quiz['id'],
                'title': quiz['title'],
                'description': quiz['description'] ?? '',
                'questionCount': quiz['questionCount'] ?? 0,
                'timeLimit': quiz['timeLimit'],
                'attemptCount': quiz['attemptCount'] ?? 0,
                'createdAt': quiz['createdAt'],
                'createdBy': quiz['createdBy'],
              }),
            )
            .toList();
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

  static Future<Map<String, dynamic>> getDashboardStats() async {
    await _addAuthInterceptor();

    try {
      final response = await _dio.get('/analytics');

      print('Response Data: ${response.data}');
      print('---');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch dashboard stats');
      }
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  static Future<void> saveQuizScore(
    String categoryId,
    int score,
    int totalQuestions,
    int percentage,
    int timeSpentMinutes,
  ) async {
    await _addAuthInterceptor();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      print('🔍 Debug - userJson from storage: $userJson');
      
      if (userJson == null) {
        print('❌ No user data found in SharedPreferences');
        throw Exception('User not found in storage');
      }
      
      final user = json.decode(userJson);
      print('🔍 Debug - parsed user object: $user');
      
      final userId = user['id'];
      print('🔍 Debug - extracted userId: $userId');
      
      if (userId == null) {
        throw Exception('User ID not found in user data');
      }

      final response = await _dio.post('/scores', data: {
        'userId': userId,
        'categoryId': categoryId,
        'score': score,
        'totalQuestions': totalQuestions,
        'percentage': percentage,
        'timeSpent': timeSpentMinutes,
      });

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception('Failed to save score to backend');
      }
    } catch (e) {
      print('Error saving score: $e');
      throw Exception('Failed to save score: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserScores([String? categoryId]) async {
    await _addAuthInterceptor();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson == null) {
        return [];
      }
      
      final user = json.decode(userJson);
      final userId = user['id'];
      
      if (userId == null) {
        return [];
      }

      final queryParams = {'userId': userId};
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }

      final response = await _dio.get('/scores', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['scores']);
      }
      return [];
    } catch (e) {
      print('Error fetching user scores: $e');
      return [];
    }
  }

  // Quiz Detail APIs
  static Future<Map<String, dynamic>?> getQuizDetail(String quizId) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.get('/quizzes/$quizId');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Get quiz detail error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getQuizQuestions(
    String quizId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      await _addAuthInterceptor();
      final response = await _dio.get(
        '/quizzes/$quizId/questions',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Get quiz questions error: $e');
      return null;
    }
  }

  static Future<List<Question>> getAllQuizQuestions(String quizId) async {
    try {
      await _addAuthInterceptor();
      List<Question> allQuestions = [];
      int page = 1;
      const int limit = 50;
      bool hasMore = true;

      while (hasMore) {
        final response = await _dio.get(
          '/quizzes/$quizId/questions',
          queryParameters: {'page': page, 'limit': limit},
        );

        if (response.statusCode == 200) {
          final data = response.data;
          final List<dynamic> questions = data['questions'] ?? [];

          allQuestions.addAll(
            questions.map((json) => Question.fromApi(json)).toList(),
          );

          final int totalPages = data['totalPages'] ?? 1;

          hasMore = page < totalPages;
          page++;
        } else {
          hasMore = false;
        }
      }

      return allQuestions;
    } catch (e) {
      print('Get all quiz questions error: $e');
      return [];
    }
  }
}
