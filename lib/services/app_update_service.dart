import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../theme/app_theme.dart';

class AppUpdateInfo {
  final bool enabled;
  final String latestVersion;
  final int latestBuild;
  final String title;
  final String message;
  final Uri? storeUrl;

  const AppUpdateInfo({
    required this.enabled,
    required this.latestVersion,
    required this.latestBuild,
    required this.title,
    required this.message,
    required this.storeUrl,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['store_url']?.toString().trim() ?? '';
    return AppUpdateInfo(
      enabled: json['enabled'] == true,
      latestVersion: json['latest_version']?.toString() ?? '0.0.0',
      latestBuild: _asInt(json['latest_build']),
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString().trim()
          : 'Доступна новая версия OySyn',
      message: json['message']?.toString().trim().isNotEmpty == true
          ? json['message'].toString().trim()
          : 'Обновите приложение, чтобы получить последние улучшения.',
      storeUrl: rawUrl.isEmpty ? null : Uri.tryParse(rawUrl),
    );
  }

  bool isNewerThan(String installedVersion, int installedBuild) {
    final comparison = compareVersions(latestVersion, installedVersion);
    return comparison > 0 || (comparison == 0 && latestBuild > installedBuild);
  }

  static int compareVersions(String left, String right) {
    final leftParts = _versionParts(left);
    final rightParts = _versionParts(right);
    final length = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;
    for (var index = 0; index < length; index++) {
      final leftValue = index < leftParts.length ? leftParts[index] : 0;
      final rightValue = index < rightParts.length ? rightParts[index] : 0;
      if (leftValue != rightValue) return leftValue.compareTo(rightValue);
    }
    return 0;
  }

  static List<int> _versionParts(String value) => value
      .split('.')
      .map((part) => int.tryParse(RegExp(r'\d+').stringMatch(part) ?? '') ?? 0)
      .toList();

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AppUpdateService {
  static const _postponeDuration = Duration(hours: 24);
  static bool _checkedThisLaunch = false;

  static Future<void> showIfNeeded(BuildContext context) async {
    if (_checkedThisLaunch || kIsWeb) return;
    _checkedThisLaunch = true;

    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
    if (platform == null) return;

    try {
      final package = await PackageInfo.fromPlatform();
      final installedBuild = int.tryParse(package.buildNumber) ?? 0;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/app/version')
            .replace(queryParameters: {'platform': platform}),
      );
      if (response.statusCode != 200) return;

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) return;
      final update = AppUpdateInfo.fromJson(payload);
      if (!update.enabled ||
          update.storeUrl == null ||
          !update.isNewerThan(package.version, installedBuild)) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final postponeKey = _postponeKey(platform, update);
      final postponedAt = DateTime.tryParse(prefs.getString(postponeKey) ?? '');
      if (postponedAt != null &&
          DateTime.now().difference(postponedAt) < _postponeDuration) {
        return;
      }
      if (!context.mounted) return;

      final shouldUpdate = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          icon: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.system_update_alt_rounded,
              color: OySynAuthTokens.primaryBlue,
              size: 28,
            ),
          ),
          title: Text(update.title, textAlign: TextAlign.center),
          content: Text(
            update.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: OySynAuthTokens.textMuted,
              height: 1.45,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Позже'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Обновить'),
            ),
          ],
        ),
      );

      if (shouldUpdate == true) {
        await launchUrl(
          update.storeUrl!,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await prefs.setString(postponeKey, DateTime.now().toIso8601String());
      }
    } catch (_) {
      // Проверка обновлений не должна мешать запуску приложения.
    }
  }

  static String _postponeKey(String platform, AppUpdateInfo update) =>
      'app_update_postponed_${platform}_${update.latestVersion}_${update.latestBuild}';
}
