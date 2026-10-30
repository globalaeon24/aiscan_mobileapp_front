import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/scan_result.dart';
import '../models/check_report.dart';
import 'api_service.dart';

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

class DeletedCheck {
  final ScanResult document;
  final DateTime? deletedAt;
  final String createdByName;
  final String createdByEmail;
  final String? deletedByName;

  const DeletedCheck({
    required this.document,
    required this.deletedAt,
    required this.createdByName,
    required this.createdByEmail,
    required this.deletedByName,
  });

  factory DeletedCheck.fromJson(Map<String, dynamic> json) {
    final createdBy = json['created_by'] is Map
        ? Map<String, dynamic>.from(json['created_by'] as Map)
        : const <String, dynamic>{};
    final deletedBy = json['deleted_by'] is Map
        ? Map<String, dynamic>.from(json['deleted_by'] as Map)
        : const <String, dynamic>{};
    return DeletedCheck(
      document: ScanResult.fromJson(json),
      deletedAt: DateTime.tryParse(json['deleted_at']?.toString() ?? ''),
      createdByName: createdBy['full_name']?.toString() ?? '',
      createdByEmail: createdBy['email']?.toString() ?? '',
      deletedByName: deletedBy['full_name']?.toString(),
    );
  }
}

class DeletedChecksPage {
  final List<DeletedCheck> items;
  final int page;
  final int pages;
  final int count;

  const DeletedChecksPage({
    required this.items,
    required this.page,
    required this.pages,
    required this.count,
  });
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

class PairCheckItem {
  final int id;
  final String firstTitle;
  final String secondTitle;
  final String firstAuthor;
  final String secondAuthor;
  final String status;
  final double firstToSecondSimilarity;
  final double secondToFirstSimilarity;
  final DateTime? createdAt;

  const PairCheckItem({
    required this.id,
    required this.firstTitle,
    required this.secondTitle,
    required this.firstAuthor,
    required this.secondAuthor,
    required this.status,
    required this.firstToSecondSimilarity,
    required this.secondToFirstSimilarity,
    required this.createdAt,
  });

  factory PairCheckItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return PairCheckItem(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0,
      firstTitle: json['a_title']?.toString() ?? '',
      secondTitle: json['b_title']?.toString() ?? '',
      firstAuthor: json['a_author']?.toString() ?? '',
      secondAuthor: json['b_author']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      firstToSecondSimilarity: ScanService._asDouble(json['a_b_similarity']),
      secondToFirstSimilarity: ScanService._asDouble(json['b_a_similarity']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class PairChecksPage {
  final List<PairCheckItem> items;
  final int count;

  const PairChecksPage({required this.items, required this.count});
}

class ScanService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// ================================================================
  /// Загрузка документа и проверка
  /// ================================================================
  static Future<ScanResult> uploadDocumentForScan(
    PlatformFile file, {
    String? title,
    String? author,
    String? department,
    String? documentType,
    bool includeOcr = false,
    bool aiCheck = true,
    List<String>? modules,
    List<String>? modulesKz,
  }) async {
    final uri = Uri.parse("$baseUrl/checks");
    var mediaType = MediaType('application', 'octet-stream');
    final name = file.name.toLowerCase();

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

    final response = await ApiService.sendMultipart((token) async {
      final request = http.MultipartRequest("POST", uri);
      request.headers["Authorization"] = "Bearer $token";
      request.fields["title"] = title == null || title.trim().isEmpty
          ? _fileTitle(file.name)
          : title.trim();
      request.fields["include_ocr"] = includeOcr.toString();
      request.fields["ocr_languages"] = "rus+kaz+eng";
      request.fields["ai_check"] = aiCheck.toString();
      if (modules != null) request.fields['modules'] = modules.join(',');
      if (modulesKz != null) {
        request.fields['modules_kz'] = modulesKz.join(',');
      }
      if (author != null && author.trim().isNotEmpty) {
        request.fields["author"] = author.trim();
      }
      if (department != null && department.trim().isNotEmpty) {
        request.fields["department"] = department.trim();
      }
      if (documentType != null && documentType.isNotEmpty) {
        request.fields["document_type"] = documentType;
      }

      final bytes = file.bytes;
      if (bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "document",
            bytes,
            filename: file.name,
            contentType: mediaType,
          ),
        );
      } else if (!kIsWeb) {
        final path = file.path;
        if (path == null || path.isEmpty) {
          throw Exception('Не удалось прочитать выбранный файл.');
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            "document",
            path,
            filename: file.name,
            contentType: mediaType,
          ),
        );
      } else {
        throw Exception(
          'Браузер не передал содержимое файла. Выберите документ повторно.',
        );
      }
      return request;
    });
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
    int? folderId,
  }) async {
    final query = <String, String>{
      "page": "$page",
      "page_size": "$pageSize",
      if (status != null && status.isNotEmpty) "status": status,
      if (folderId != null) "folder_id": "$folderId",
    };
    final uri = Uri.parse("$baseUrl/checks").replace(queryParameters: query);
    final res = await ApiService.get('/checks?${uri.query}');

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final rawItems = json is List
          ? json
          : (json["results"] ?? json["items"] ?? json["data"] ?? []) as List;
      final items = rawItems
          .map((e) => ScanResult.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final responsePage = _asInt(json is Map ? json["page"] : null) ?? page;
      final total = _asInt(json is Map
          ? (json["count"] ?? json["total"] ?? json["total_count"])
          : null);
      final pages = _asInt(json is Map ? json["pages"] : null) ??
          (total == null || total <= 0 ? null : (total / pageSize).ceil());

      return CheckHistoryPage(
        items: items,
        page: responsePage,
        pageSize: pageSize,
        total: total,
        hasNext: json is Map
            ? (json["next"] != null || (pages != null && responsePage < pages))
            : items.length == pageSize,
        hasPrevious: json is Map
            ? (json["previous"] != null || responsePage > 1)
            : page > 1,
      );
    } else {
      throw Exception("Ошибка истории: ${res.statusCode} ${res.body}");
    }
  }

  static Future<List<ScanResult>> getAllHistory({int? folderId}) async {
    const pageSize = 100;
    const maxPages = 50;
    final items = <ScanResult>[];
    for (var page = 1; page <= maxPages; page++) {
      final result = await getHistoryPage(
        page: page,
        pageSize: pageSize,
        folderId: folderId,
      );
      items.addAll(result.items);
      if (!result.hasNext) break;
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<void> deleteCheck(int id) async {
    final response = await ApiService.delete('/checks/$id');
    if (response.statusCode == 404) return;
    if (response.statusCode == 405 || response.statusCode == 501) {
      throw Exception('Удаление документов пока не поддерживается Core.');
    }
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_responseMessage(
        response.body,
        'Не удалось удалить документ (${response.statusCode}).',
      ));
    }
  }

  static Future<DeletedChecksPage> getDeletedChecks(
    int organizationId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await ApiService.get(
      '/organizations/$organizationId/checks/deleted?page=$page&page_size=$pageSize',
    );
    if (response.statusCode != 200) {
      throw Exception(
        response.statusCode == 403
            ? 'Раздел доступен только администратору организации.'
            : 'Не удалось загрузить удалённые документы (${response.statusCode}).',
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw Exception('Сервер вернул некорректный список документов.');
    }
    final rawItems = payload['results'] is List
        ? payload['results'] as List
        : const <dynamic>[];
    return DeletedChecksPage(
      items: rawItems
          .whereType<Map>()
          .map((item) => DeletedCheck.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      page: _asInt(payload['page']) ?? page,
      pages: _asInt(payload['pages']) ?? 1,
      count: _asInt(payload['count']) ?? rawItems.length,
    );
  }

  static Future<void> restoreDeletedCheck(
    int organizationId,
    int checkId,
  ) async {
    final response = await ApiService.post(
      '/organizations/$organizationId/checks/$checkId/restore',
    );
    if (response.statusCode != 200) {
      throw Exception(
        response.statusCode == 403
            ? 'Восстановление доступно только администратору организации.'
            : 'Не удалось восстановить документ (${response.statusCode}).',
      );
    }
  }

  static Future<List<CheckModule>> getCheckModules() async {
    final response = await ApiService.get('/checks/modules');
    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить модули: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => CheckModule.fromJson(item as Map<String, dynamic>))
        .where((item) => item.code.isNotEmpty)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getFolders() async {
    final response = await ApiService.get('/folders');
    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить папки: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  static Future<Map<String, dynamic>> createFolder(String name) async {
    final response = await ApiService.post('/folders', body: {'name': name});
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Не удалось создать папку (${response.statusCode}).');
    }
    final payload = jsonDecode(response.body);
    return payload is Map<String, dynamic> ? payload : const {};
  }

  static Future<Map<String, dynamic>> renameFolder(
    int folderId,
    String name,
  ) async {
    final response = await ApiService.patch(
      '/folders/$folderId',
      body: {'name': name},
    );
    if (response.statusCode != 200) {
      throw Exception(_responseMessage(
        response.body,
        'Не удалось переименовать папку (${response.statusCode}).',
      ));
    }
    final payload = jsonDecode(response.body);
    return payload is Map<String, dynamic> ? payload : const {};
  }

  static Future<void> assignCheckFolder(int checkId, int? folderId) async {
    final response = await ApiService.patch(
      '/checks/$checkId',
      body: {'folder_id': folderId},
    );
    if (response.statusCode != 200) {
      throw Exception(_responseMessage(
        response.body,
        'Не удалось изменить папку документа (${response.statusCode}).',
      ));
    }
  }

  static String _responseMessage(String body, String fallback) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic>) {
        final detail =
            payload['detail'] ?? payload['error'] ?? payload['message'];
        if (detail != null && detail.toString().trim().isNotEmpty) {
          return detail.toString().trim();
        }
      }
    } catch (_) {}
    return fallback;
  }

  static Future<PairChecksPage> getPairChecks() async {
    final response = await ApiService.get('/checks/pair-checks');
    if (response.statusCode != 200) {
      throw Exception(
          'Не удалось загрузить парные проверки (${response.statusCode}).');
    }
    final payload = jsonDecode(response.body);
    final rawItems =
        payload is Map<String, dynamic> && payload['results'] is List
            ? payload['results'] as List
            : const <dynamic>[];
    return PairChecksPage(
      items: rawItems
          .whereType<Map>()
          .map(
              (item) => PairCheckItem.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id > 0)
          .toList(),
      count:
          _asInt(payload is Map<String, dynamic> ? payload['count'] : null) ??
              rawItems.length,
    );
  }

  static Future<int> createPairCheck({
    required PlatformFile firstDocument,
    required PlatformFile secondDocument,
    required String firstTitle,
    required String secondTitle,
    required String firstAuthor,
    required String secondAuthor,
  }) async {
    final uri = Uri.parse('$baseUrl/checks/pair-checks');
    final response = await ApiService.sendMultipart((token) async {
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll({
        'a_title': firstTitle.trim(),
        'b_title': secondTitle.trim(),
        'a_author': firstAuthor.trim(),
        'b_author': secondAuthor.trim(),
      });
      request.files.add(await _pairFilePart('a_document', firstDocument));
      request.files.add(await _pairFilePart('b_document', secondDocument));
      return request;
    });
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200 && response.statusCode != 201) {
      var message = 'Не удалось запустить парную проверку.';
      try {
        final payload = jsonDecode(body);
        if (payload is Map<String, dynamic>) {
          final detail = payload['detail'] ?? payload['error'];
          if (detail != null && '$detail'.trim().isNotEmpty) {
            message = '$detail'.trim();
          }
        }
      } catch (_) {}
      throw Exception(message);
    }
    final payload = jsonDecode(body);
    return _asInt(payload is Map<String, dynamic> ? payload['id'] : null) ?? 0;
  }

  static Future<http.MultipartFile> _pairFilePart(
    String field,
    PlatformFile file,
  ) async {
    final mediaType = _mediaTypeForFile(file.name);
    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        field,
        file.bytes!,
        filename: file.name,
        contentType: mediaType,
      );
    }
    if (file.path != null && file.path!.isNotEmpty) {
      return http.MultipartFile.fromPath(
        field,
        file.path!,
        filename: file.name,
        contentType: mediaType,
      );
    }
    throw Exception('Не удалось прочитать выбранный файл.');
  }

  static MediaType _mediaTypeForFile(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (name.endsWith('.docx')) {
      return MediaType(
        'application',
        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    }
    if (name.endsWith('.doc')) return MediaType('application', 'msword');
    if (name.endsWith('.txt')) return MediaType('text', 'plain');
    return MediaType('application', 'octet-stream');
  }

  /// ================================================================
  /// 5) Детальный результат
  /// ================================================================
  static Future<ScanResult> getScanById(int id) async {
    final res = await ApiService.get('/checks/$id');

    if (res.statusCode == 200) {
      return ScanResult.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      throw Exception("Проверка не найдена.");
    } else {
      throw Exception(_responseMessage(
        res.body,
        'Не удалось загрузить проверку (${res.statusCode}).',
      ));
    }
  }

  static Future<CheckReport> getReport(int id) async {
    final response = await ApiService.get('/checks/$id/report');
    if (response.statusCode != 200) {
      throw Exception(_responseMessage(
        response.body,
        'Отчёт пока недоступен (${response.statusCode}).',
      ));
    }
    return CheckReport.fromJson(jsonDecode(response.body));
  }

  static Future<Uint8List> getReportPdf(
    int id, {
    String reportType = 'certificate',
    String language = 'ru',
  }) async {
    final uri =
        Uri(path: '/checks/$id/report/pdf/$reportType', queryParameters: {
      'lang': language,
    });
    final response = await ApiService.get(uri.toString());
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить PDF: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  static Future<Uint8List> getPairReportPdf(
    int id, {
    String reportType = 'full',
    String language = 'ru',
  }) async {
    if (reportType != 'full' && reportType != 'short') {
      throw ArgumentError.value(reportType, 'reportType');
    }
    final uri = Uri(
      path: '/checks/pair-checks/$id/report/pdf/$reportType',
      queryParameters: {'lang': language},
    );
    final response = await ApiService.get(uri.toString());
    if (response.statusCode != 200) {
      throw Exception(_responseMessage(
        response.body,
        'PDF-отчёт пока недоступен (${response.statusCode}).',
      ));
    }
    return response.bodyBytes;
  }

  static String _fileTitle(String name) {
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
