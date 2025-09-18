import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return json.decode(userJson);
    }
    return null;
  }

  static Future<bool> login(String email, String password) async {
    try {
      final result = await ApiService.login(email, password);
      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(result['user']));
        await prefs.setString(_tokenKey, result['token'] ?? '');
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  static Future<bool> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final result = await ApiService.register(email, password, name);
      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(result['user']));
        await prefs.setString(_tokenKey, result['token'] ?? '');
        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  static Future<String?> getUserId() async {
    final user = await getCurrentUser();
    return user?['id'];
  }

  static Future<String?> getUserName() async {
    final user = await getCurrentUser();
    return user?['name'];
  }

  static Future<String?> getUserEmail() async {
    final user = await getCurrentUser();
    return user?['email'];
  }
}
