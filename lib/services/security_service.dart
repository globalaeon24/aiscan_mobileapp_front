import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  SecurityService._();

  static const _storage = FlutterSecureStorage();
  static final _auth = LocalAuthentication();

  static const _pinHashKey = 'security_pin_hash';
  static const _pinSaltKey = 'security_pin_salt';
  static const _pinAlgorithmKey = 'security_pin_algorithm';
  static const _pinIterationsKey = 'security_pin_iterations';
  static const _pinAlgorithm = 'pbkdf2-sha256-v1';
  static const _biometricEnabledKey = 'security_biometric_enabled';
  static const _pinIterations = 120000;
  static const _webPinIterations = 10000;

  static Future<bool> isSecurityConfigured() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  static Future<void> savePin(String pin) async {
    final iterations = kIsWeb ? _webPinIterations : _pinIterations;
    final random = Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(
      key: _pinHashKey,
      value: await _hashPin(pin, salt, iterations),
    );
    await _storage.write(key: _pinAlgorithmKey, value: _pinAlgorithm);
    await _storage.write(
      key: _pinIterationsKey,
      value: '$iterations',
    );
  }

  static Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final hash = await _storage.read(key: _pinHashKey);
    if (salt == null || hash == null) return false;
    final algorithm = await _storage.read(key: _pinAlgorithmKey);
    if (algorithm == null) {
      final legacyHash = sha256.convert(utf8.encode('$salt:$pin')).toString();
      if (!_constantTimeEquals(legacyHash, hash)) return false;
      await savePin(pin);
      return true;
    }
    if (algorithm != _pinAlgorithm) return false;
    final storedIterations = int.tryParse(
      await _storage.read(key: _pinIterationsKey) ?? '',
    );
    final iterations = storedIterations ?? _pinIterations;
    return _constantTimeEquals(
      await _hashPin(pin, salt, iterations),
      hash,
    );
  }

  static Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBiometricEnabled() async {
    return await _storage.read(key: _biometricEnabledKey) == 'true';
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  static Future<bool> authenticateWithBiometrics({
    String reason = 'Подтвердите вход в OySyn',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _storage.delete(key: _pinAlgorithmKey);
    await _storage.delete(key: _pinIterationsKey);
    await _storage.delete(key: _biometricEnabledKey);
  }

  static Future<String> _hashPin(
    String pin,
    String salt,
    int iterations,
  ) {
    if (kIsWeb) {
      return Future<String>(() => _derivePinHash(pin, salt, iterations));
    }
    return Isolate.run(
      () => _derivePinHash(pin, salt, iterations),
    );
  }

  static bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}

String _derivePinHash(String pin, String salt, int iterations) {
  final key = utf8.encode(pin);
  final saltBytes = base64Url.decode(salt);
  final hmac = Hmac(sha256, key);
  var block = hmac.convert([...saltBytes, 0, 0, 0, 1]).bytes;
  final derived = List<int>.from(block);

  for (var round = 1; round < iterations; round++) {
    block = hmac.convert(block).bytes;
    for (var index = 0; index < derived.length; index++) {
      derived[index] ^= block[index];
    }
  }
  return base64UrlEncode(derived);
}
