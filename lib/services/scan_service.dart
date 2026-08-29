import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import '../models/scan_result.dart';
import '../models/check_report.dart';

class CheckHistoryPage {
  final List<ScanResult> items;
  final int page;
  final int pageSize;
  final int? total;
  final bool hasNext;
  final bool hasPrevious;

  const CheckHistoryPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasNext,
    required this.hasPrevious,
  });

  int? get totalPages {
    final count = total;
    if (count == null || count <= 0) return null;
    return (count / pageSize).ceil();
  }
}

class CheckModule {
  final String code;
  final String label;
  final String group;
  final bool required;
  final bool selected;

  const CheckModule({
    required this.code,
    required this.label,
    required this.group,
    required this.required,
    required this.selected,
  });

  factory CheckModule.fromJson(Map<String, dynamic> json) => CheckModule(
        code: json['code']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        group: json['group']?.toString() ?? 'base',
        required: json['required'] == true,
        selected: json['selected'] != false,
      );
}

class ScanService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// ================================================================
  /// 1) OCR — отправка изображения на backend
  /// ================================================================
  static Future<String> uploadImageForOCR(File file) async {
    throw UnsupportedError(
      "OCR изображения через mobile backend больше не поддерживается. "
      "Загрузите документ через проверку /api/v1/checks.",
    );
  }

  /// ================================================================
  /// 2) Загрузка документа и проверка
  /// ================================================================
  static Future<ScanResult> uploadDocumentForScan(
    File file, {
    String? title,
    String? author,
    String? department,
    String? documentType,
    bool includeOcr = false,
    bool aiCheck = true,
    List<String>? modules,
    List<String>? modulesKz,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Нет токена авторизации.");
    }

    final uri = Uri.parse("$baseUrl/checks");
    final request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer $token";
    request.fields["title"] =
        title == null || title.trim().isEmpty ? _fileTitle(file) : title.trim();
    request.fields["include_ocr"] = includeOcr.toString();
    request.fields["ocr_languages"] = "rus+kaz+eng";
    request.fields["ai_check"] = aiCheck.toString();
    if (modules != null) request.fields['modules'] = modules.join(',');
    if (modulesKz != null) request.fields['modules_kz'] = modulesKz.join(',');
    if (author != null && author.trim().isNotEmpty) {
      request.fields["author"] = author.trim();
    }
    if (department != null && department.trim().isNotEmpty) {
      request.fields["department"] = department.trim();
    }
    if (documentType != null && documentType.isNotEmpty) {
      request.fields["document_type"] = documentType;
    }

    var mediaType = MediaType('application', 'octet-stream');
    final name = file.path.toLowerCase();

    if (name.endsWith('.pdf')) {
      mediaType = MediaType('application', 'pdf');
    }
    if (name.endsWith('.docx')) {
      mediaType = MediaType(
        'application',
        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    }
    if (name.endsWith('.doc')) {
      mediaType = MediaType('application', 'msword');
    }
    if (name.endsWith('.txt')) {
      mediaType = MediaType('text', 'plain');
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        "document",
        file.path,
        contentType: mediaType,
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ScanResult.fromJson(jsonDecode(body));
    } else {
      var message = 'Не удалось загрузить документ.';
      try {
        final payload = jsonDecode(body);
        if (payload is Map<String, dynamic>) {
          final detail = payload['detail'] ?? payload['error'];
          if (detail is String && detail.trim().isNotEmpty) {
            message = detail.trim();
          }
        }
      } catch (_) {}
      if (response.statusCode == 402 || response.statusCode == 403) {
        message =
            'Лимит проверок исчерпан. Обратитесь к администратору организации.';
      }
      throw Exception(message);
    }
  }

  /// ================================================================
  /// 3) Создание проверки по тексту
  /// ================================================================
  static Future<ScanResult> createScan(String text) async {
    throw UnsupportedError(
      "Проверка вставленного текста через mobile backend больше не поддерживается. "
      "Создайте проверку документом через /api/v1/checks.",
    );
  }

  /// ================================================================
  /// 4) История проверок (БЕЗ ai_fragments)
  /// ================================================================
  static Future<List<ScanResult>> getHistory() async {
    final page = await getHistoryPage(page: 1, pageSize: 20);
    return page.items;
  }

  static Future<CheckHistoryPage> getHistoryPage({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Нет токена авторизации.");
    }

    final query = <String, String>{
      "page": "$page",
      "page_size": "$pageSize",
      if (status != null && status.isNotEmpty) "status": status,
    };
    final uri = Uri.parse("$baseUrl/checks").replace(queryParameters: query);
    final res =
        await http.get(uri, headers: {"Authorization": "Bearer $token"});

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final rawItems = json is List
          ? json
          : (json["results"] ?? json["items"] ?? json["data"] ?? []) as List;
      final items = rawItems
          .map((e) => ScanResult.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return CheckHistoryPage(
        items: items,
        page: _asInt(json is Map ? json["page"] : null) ?? page,
        pageSize: pageSize,
        total: _asInt(json is Map
            ? (json["count"] ?? json["total"] ?? json["total_count"])
            : null),
        hasNext: json is Map ? json["next"] != null : items.length == pageSize,
        hasPrevious: json is Map ? json["previous"] != null : page > 1,
      );
    } else {
      throw Exception("Ошибка истории: ${res.statusCode} ${res.body}");
    }
  }

  static Future<List<CheckModule>> getCheckModules() async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Нет токена авторизации.');

    final response = await http.get(
      Uri.parse('$baseUrl/checks/modules'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить модули: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => CheckModule.fromJson(item as Map<String, dynamic>))
        .where((item) => item.code.isNotEmpty)
        .toList();
  }

  /// ================================================================
  /// 5) Детальный результат
  /// ================================================================
  static Future<ScanResult> getScanById(int id) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Нет токена.");
    }

    final uri = Uri.parse("$baseUrl/checks/$id");
    final res =
        await http.get(uri, headers: {"Authorization": "Bearer $token"});

    if (res.statusCode == 200) {
      return ScanResult.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      throw Exception("Проверка не найдена.");
    } else {
      throw Exception("Ошибка загрузки: ${res.statusCode} ${res.body}");
    }
  }

  static Future<CheckReport> getReport(int id) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Нет токена авторизации.');

    final response = await http.get(
      Uri.parse('$baseUrl/checks/$id/report'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Отчёт пока недоступен: ${response.statusCode}');
    }
    return CheckReport.fromJson(jsonDecode(response.body));
  }

  static Future<Uint8List> getReportPdf(
    int id, {
    String reportType = 'certificate',
    String language = 'ru',
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Нет токена авторизации.');

    final uri = Uri.parse('$baseUrl/checks/$id/report/pdf/$reportType')
        .replace(queryParameters: {'lang': language});
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить PDF: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  static String _fileTitle(File file) {
    final path = file.path;
    final separator = Platform.pathSeparator;
    final name = path.contains(separator) ? path.split(separator).last : path;
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
