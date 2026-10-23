import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_result.dart';

class TokenStorage {
  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );
  static const _key = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'current_user';
  static const _historyKey = 'cached_check_history';
  static const _notificationsReadAtKey = 'notifications_read_at';
  static const _installationMarkerKey = 'secure_storage_initialized';

  static final ValueNotifier<Map<String, dynamic>?> userListenable =
      ValueNotifier<Map<String, dynamic>?>(null);

  static Future<void> saveToken(String token) async {
    await _ensureInstallationState();
    await _secureStorage.write(key: _key, value: token);
    await _removeLegacySecret(_key);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _ensureInstallationState();
    await _secureStorage.write(key: _refreshKey, value: token);
    await _removeLegacySecret(_refreshKey);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final snapshot = Map<String, dynamic>.from(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(snapshot));
    userListenable.value = snapshot;
  }

  static Future<String?> getToken() async {
    return _readAndMigrateSecret(_key);
  }

  static Future<String?> getRefreshToken() async {
    return _readAndMigrateSecret(_refreshKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      userListenable.value = decoded;
      return decoded;
    }
    return null;
  }

  static Future<void> saveHistory(List<ScanResult> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = items.take(100).map((item) {
      final summary = item.toJson();
      summary.remove('scanned_text');
      summary.remove('highlighted_text');
      summary.remove('ai_fragments');
      return summary;
    }).toList();
    await prefs.setString(_historyKey, jsonEncode(payload));
  }

  static Future<List<ScanResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ScanResult.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<DateTime?> getNotificationsReadAt() async {
    final prefs = await SharedPreferences.getInstance();
    return DateTime.tryParse(prefs.getString(_notificationsReadAtKey) ?? '');
  }

  static Future<void> markNotificationsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notificationsReadAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
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
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _key);
    await _secureStorage.delete(key: _refreshKey);
    await prefs.remove(_key);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
    await prefs.remove(_historyKey);
    await prefs.remove(_notificationsReadAtKey);
    userListenable.value = null;
  }

  static Future<String?> _readAndMigrateSecret(String key) async {
    await _ensureInstallationState();
    final secureValue = await _secureStorage.read(key: key);
    if (secureValue != null && secureValue.isNotEmpty) return secureValue;

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getString(key);
    if (legacyValue == null || legacyValue.isEmpty) return null;

    await _secureStorage.write(key: key, value: legacyValue);
    await prefs.remove(key);
    return legacyValue;
  }

  static Future<void> _removeLegacySecret(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> _ensureInstallationState() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_installationMarkerKey) == true) return;

    final hasLegacySession = (prefs.getString(_key)?.isNotEmpty ?? false) ||
        (prefs.getString(_refreshKey)?.isNotEmpty ?? false);
    if (!hasLegacySession) {
      await _secureStorage.delete(key: _key);
      await _secureStorage.delete(key: _refreshKey);
    }
    await prefs.setBool(_installationMarkerKey, true);
  }
}
