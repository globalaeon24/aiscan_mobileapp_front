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
  final int minimumSupportedBuild;
  final bool updateRequired;
  final int remindAfterHours;
  final String title;
  final String message;
  final Uri? storeUrl;

  const AppUpdateInfo({
    required this.enabled,
    required this.latestVersion,
    required this.latestBuild,
    required this.minimumSupportedBuild,
    required this.updateRequired,
    required this.remindAfterHours,
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
      minimumSupportedBuild: _asInt(json['minimum_supported_build']),
      updateRequired:
          json['update_required'] == true || json['force_update'] == true,
      remindAfterHours: _positiveInt(json['remind_after_hours'], fallback: 24),
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

  bool isRequiredFor(int installedBuild) =>
      updateRequired ||
      (minimumSupportedBuild > 0 && installedBuild < minimumSupportedBuild);

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

  static int _positiveInt(dynamic value, {required int fallback}) {
    final parsed = _asInt(value);
    return parsed > 0 ? parsed : fallback;
  }
}

class AppUpdateService {
  static const _minimumCheckInterval = Duration(minutes: 5);
  static bool _dialogVisible = false;
  static DateTime? _lastCheckedAt;

  static Future<void> showIfNeeded(BuildContext context) async {
    if (_dialogVisible || kIsWeb) return;

    final now = DateTime.now();
    if (_lastCheckedAt != null &&
        now.difference(_lastCheckedAt!) < _minimumCheckInterval) {
      return;
    }
    _lastCheckedAt = now;

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
      final nextPromptAt =
          DateTime.tryParse(prefs.getString(postponeKey) ?? '');
      final required = update.isRequiredFor(installedBuild);
      if (!required && nextPromptAt != null && now.isBefore(nextPromptAt)) {
        return;
      }
      if (!context.mounted) return;

      _dialogVisible = true;
      final shouldUpdate = await showDialog<bool>(
        context: context,
        barrierDismissible: !required,
        builder: (dialogContext) => PopScope(
          canPop: !required,
          child: AlertDialog(
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
              if (!required)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Позже'),
                ),
              FilledButton.icon(
                onPressed: () async {
                  if (required) {
                    await _openStore(update.storeUrl!);
                  } else {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Обновить'),
              ),
            ],
          ),
        ),
      );
      _dialogVisible = false;

      if (shouldUpdate == true) {
        await _openStore(update.storeUrl!);
      } else if (!required) {
        final nextPrompt = DateTime.now().add(
          Duration(hours: update.remindAfterHours),
        );
        await prefs.setString(postponeKey, nextPrompt.toIso8601String());
      }
    } catch (_) {
      _dialogVisible = false;
      // Проверка обновлений не должна мешать запуску приложения.
    }
  }

  static Future<void> _openStore(Uri storeUrl) => launchUrl(
        storeUrl,
        mode: LaunchMode.externalApplication,
      );

  static String _postponeKey(String platform, AppUpdateInfo update) =>
      'app_update_postponed_${platform}_${update.latestVersion}_${update.latestBuild}';
}
