import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _key = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'current_user';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshKey, token);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }

  static String displayName(Map<String, dynamic>? user) {
    if (user == null) return 'Пользователь';
    final fullName = user['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    final firstName = user['first_name']?.toString().trim();
    final lastName = user['last_name']?.toString().trim();
    final parts = [
      if (firstName != null && firstName.isNotEmpty) firstName,
      if (lastName != null && lastName.isNotEmpty) lastName,
    ];
    if (parts.isNotEmpty) return parts.join(' ');

    final email = user['email']?.toString().trim();
    if (email != null && email.isNotEmpty) return email;
    return 'Пользователь';
  }

  static String initials(Map<String, dynamic>? user) {
    final name = displayName(user);
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }
}
