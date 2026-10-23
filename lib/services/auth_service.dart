import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'device_identity_service.dart';

class AuthService {
  static const baseUrl = ApiConfig.baseUrl;
  static const _demoEnabled = bool.fromEnvironment('ENABLE_DEMO_LOGIN');
  static const _demoUsername = String.fromEnvironment('DEMO_USERNAME');
  static const _demoPassword = String.fromEnvironment('DEMO_PASSWORD');
  static String? lastLoginError;

  /// ---------- ЛОГИН ----------
  static Future<bool> login(String email, String password) async {
    lastLoginError = null;
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    final normalizedLogin = trimmedEmail.toLowerCase();
    if (_demoEnabled &&
        _demoUsername.isNotEmpty &&
        normalizedLogin == _demoUsername.toLowerCase() &&
        trimmedPassword == _demoPassword) {
      await TokenStorage.saveToken('demo_oysyn_token');
      await TokenStorage.saveUser({
        "full_name": "Demo User",
        "email": "oysyn",
      });
      return true;
    }

    late final http.Response res;
    try {
      Map<String, dynamic> deviceMetadata;
      try {
        deviceMetadata = await DeviceIdentityService.loginMetadata();
      } catch (_) {
        deviceMetadata = const {};
      }
      res = await http
          .post(
            Uri.parse("$baseUrl/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": trimmedEmail,
              "password": trimmedPassword,
              ...deviceMetadata,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      lastLoginError = "Сервер отвечает слишком долго. Попробуйте ещё раз.";
      return false;
    } catch (error, stackTrace) {
      debugPrint('Auth login request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      lastLoginError = "Нет связи с сервером. Проверьте интернет-соединение.";
      return false;
    }

    if (res.statusCode == 200) {
      final data = _decodeBody(res.body);
      if (data is! Map<String, dynamic>) {
        lastLoginError = "Сервер вернул некорректный ответ.";
        return false;
      }
      final token = data["access_token"];
      final refreshToken = data["refresh_token"];
      final user = data["user"];

      if (token == null) {
        lastLoginError = "Сервер не вернул токен авторизации.";
        return false;
      }

      await TokenStorage.saveToken(token);
      if (refreshToken != null) {
        await TokenStorage.saveRefreshToken(refreshToken);
      }
      if (user is Map<String, dynamic>) {
        await TokenStorage.saveUser(user);
      }
      return true;
    }

    lastLoginError = _extractErrorMessage(res);
    return false;
  }

  static Future<bool> refreshSession() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return false;

      final data = _decodeBody(res.body);
      if (data is! Map<String, dynamic>) return false;
      final accessToken = data['access_token']?.toString();
      final rotatedRefreshToken = data['refresh_token']?.toString();
      if (accessToken == null || accessToken.isEmpty) return false;

      await TokenStorage.saveToken(accessToken);
      if (rotatedRefreshToken != null && rotatedRefreshToken.isNotEmpty) {
        await TokenStorage.saveRefreshToken(rotatedRefreshToken);
      }
      final user = data['user'];
      if (user is Map<String, dynamic>) await TokenStorage.saveUser(user);
      return true;
    } catch (_) {
      return false;
    }
  }

  static dynamic _decodeBody(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String _extractErrorMessage(http.Response response) {
    final decoded = _decodeBody(response.body);
    final serverMessage = decoded is Map<String, dynamic>
        ? (decoded["detail"] ?? decoded["error"] ?? decoded["message"])
            ?.toString()
            .toLowerCase()
        : null;

    return switch (response.statusCode) {
      400 || 401 => "Неверный логин или пароль.",
      403 when serverMessage?.contains("заблок") == true =>
        "Учётная запись заблокирована. Обратитесь к администратору.",
      403 => "Вход для этой учётной записи ограничен.",
      404 => "Сервис авторизации временно недоступен.",
      408 => "Сервер отвечает слишком долго. Попробуйте ещё раз.",
      422 => "Проверьте, что логин и пароль заполнены правильно.",
      429 => "Слишком много попыток входа. Повторите немного позже.",
      >= 500 => "Сервис временно недоступен. Попробуйте позже.",
      _ => "Не удалось войти. Попробуйте ещё раз.",
    };
  }

  static Future<RegistrationResult> register(
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
              'password_confirmation': passwordConfirmation,
              'agreement_accepted': true,
              'agreement_version': '2026-10-22',
              'agreement_url': 'https://oysyn.asia/ru/policy/',
            }),
          )
          .timeout(const Duration(seconds: 20));

      final decoded = _decodeBody(response.body);
      final payload =
          decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
      final code = payload['code']?.toString();
      final message = payload['message']?.toString();

      return switch (code) {
        'registration_created' => RegistrationResult(
            code: RegistrationCode.created,
            message: message ?? 'Аккаунт создан. Подтвердите email.',
          ),
        'email_not_verified' => RegistrationResult(
            code: RegistrationCode.emailNotVerified,
            message: message ?? 'Email ещё не подтверждён.',
          ),
        'account_already_exists' => RegistrationResult(
            code: RegistrationCode.accountAlreadyExists,
            message: message ?? 'Аккаунт с таким email уже существует.',
          ),
        _ => RegistrationResult(
            code: RegistrationCode.error,
            message: _registrationErrorMessage(response.statusCode, payload),
          ),
      };
    } on TimeoutException {
      return const RegistrationResult(
        code: RegistrationCode.error,
        message: 'Сервер отвечает слишком долго. Попробуйте ещё раз.',
      );
    } catch (error, stackTrace) {
      debugPrint('Auth registration request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const RegistrationResult(
        code: RegistrationCode.error,
        message: 'Нет связи с сервером. Проверьте интернет-соединение.',
      );
    }
  }

  static String _registrationErrorMessage(
    int statusCode,
    Map<String, dynamic> payload,
  ) {
    final serverMessage =
        (payload['message'] ?? payload['detail'] ?? payload['error'])
            ?.toString();
    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return serverMessage.trim();
    }
    return switch (statusCode) {
      422 => 'Проверьте правильность заполнения полей.',
      429 => 'Слишком много попыток. Повторите немного позже.',
      >= 500 => 'Сервис регистрации временно недоступен. Попробуйте позже.',
      _ => 'Не удалось создать аккаунт. Попробуйте ещё раз.',
    };
  }
}

enum RegistrationCode {
  created,
  emailNotVerified,
  accountAlreadyExists,
  error,
}

class RegistrationResult {
  const RegistrationResult({required this.code, required this.message});

  final RegistrationCode code;
  final String message;
}
