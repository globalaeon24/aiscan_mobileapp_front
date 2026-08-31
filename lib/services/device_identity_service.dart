import 'dart:convert';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentityService {
  static const _installationIdKey = 'mobile_installation_id';

  const DeviceIdentityService._();

  static Future<Map<String, dynamic>> loginMetadata() async {
    final package = await PackageInfo.fromPlatform();
    final installationId = await _installationId();
    final metadata = <String, dynamic>{
      'device_id': installationId,
      'app_version': '${package.version}+${package.buildNumber}',
    };

    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await info.webBrowserInfo;
        metadata.addAll({
          'platform': 'web',
          'device_name': web.browserName.name,
          'device_model': web.platform,
          'os_version': web.userAgent,
        });
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final android = await info.androidInfo;
            metadata.addAll({
              'platform': 'android',
              'device_name': _androidName(android),
              'device_model': android.model,
              'os_version': android.version.release,
            });
          case TargetPlatform.iOS:
            final ios = await info.iosInfo;
            metadata.addAll({
              'platform': 'ios',
              'device_name': ios.name,
              'device_model': ios.utsname.machine,
              'os_version': ios.systemVersion,
            });
          case TargetPlatform.macOS:
            final mac = await info.macOsInfo;
            metadata.addAll({
              'platform': 'macos',
              'device_name': mac.computerName,
              'device_model': mac.model,
              'os_version': mac.osRelease,
            });
          case TargetPlatform.windows:
            final windows = await info.windowsInfo;
            metadata.addAll({
              'platform': 'windows',
              'device_name': windows.computerName,
              'device_model': windows.productName,
              'os_version': windows.displayVersion,
            });
          case TargetPlatform.linux:
            final linux = await info.linuxInfo;
            metadata.addAll({
              'platform': 'linux',
              'device_name': linux.prettyName,
              'device_model': linux.name,
              'os_version': linux.version,
            });
          case TargetPlatform.fuchsia:
            metadata.addAll({
              'platform': 'fuchsia',
              'device_name': 'Fuchsia устройство',
            });
        }
      }
    } catch (_) {
      metadata.addAll({
        'platform': _platformName(),
        'device_name': '${_platformName()} устройство',
      });
    }

    return metadata;
  }

  static String _androidName(AndroidDeviceInfo info) {
    final manufacturer = info.manufacturer.trim();
    final model = info.model.trim();
    if (manufacturer.isEmpty) return model;
    if (model.toLowerCase().startsWith(manufacturer.toLowerCase())) {
      return model;
    }
    return '$manufacturer $model';
  }

  static Future<String> _installationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installationIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final value = base64UrlEncode(bytes).replaceAll('=', '');
    await prefs.setString(_installationIdKey, value);
    return value;
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
