import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../storage/token_storage.dart';
import '../models/scan_result.dart';

class ScanService {
  static const String baseUrl = "http://194.146.43.172:8082/api";

  /// ================================================================
  /// 1) OCR — отправка изображения на backend
  /// ================================================================
  static Future<String> uploadImageForOCR(File file) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Нет токена авторизации.");
    }

    final uri = Uri.parse("$baseUrl/scan/ocr");

    final lower = file.path.toLowerCase();
    String subtype = 'jpeg';
    if (lower.endsWith('.png')) subtype = 'png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) subtype = 'jpeg';

    final request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer $token";

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        file.path,
        contentType: MediaType("image", subtype),
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return data["text"];
    } else {
      throw Exception("Ошибка OCR: ${response.statusCode} $body");
    }
  }

  /// ================================================================
  /// 2) Загрузка документа и проверка
  /// ================================================================
  static Future<ScanResult> uploadDocumentForScan(File file) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Нет токена авторизации.");
    }

    final uri = Uri.parse("$baseUrl/scan/file");
    final request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer $token";

    String subtype = 'octet-stream';
    final name = file.path.toLowerCase();

    if (name.endsWith('.pdf')) subtype = 'pdf';
    if (name.endsWith('.docx')) {
      subtype = 'vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (name.endsWith('.doc')) subtype = 'msword';

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        file.path,
        contentType: MediaType("application", subtype),
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return ScanResult.fromJson(jsonDecode(body));
    } else {
      throw Exception("Ошибка загрузки документа: ${response.statusCode} $body");
    }
  }

  /// ================================================================
  /// 3) Создание проверки по тексту
  /// ================================================================
  static Future<ScanResult> createScan(String text) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Не найден токен авторизации.");
    }

    final uri = Uri.parse("$baseUrl/scan/");
    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"scanned_text": text}),
    );

    if (res.statusCode == 200) {
      return ScanResult.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("Ошибка создания проверки: ${res.statusCode} ${res.body}");
    }
  }

  /// ================================================================
  /// 4) История проверок (БЕЗ ai_fragments)
  /// ================================================================
  static Future<List<ScanResult>> getHistory() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Нет токена авторизации.");
    }

    final uri = Uri.parse("$baseUrl/scan/history");
    final res = await http.get(uri, headers: {"Authorization": "Bearer $token"});

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final items = (json["items"] as List).cast<Map<String, dynamic>>();

      return items.map((e) {
        return ScanResult(
          id: e["id"],
          aiPercentage: (e["ai_percentage"] as num).toDouble(),
          scannedText: "",
          highlightedText: null,
          createdAt: DateTime.parse(e["created_at"]),
          aiFragments: const [], // 🔥 КЛЮЧЕВО
          userScanIndex: e["user_scan_index"],
          fileName: e["file_name"],
          authorName: null,
        );
      }).toList();
    } else {
      throw Exception("Ошибка истории: ${res.statusCode} ${res.body}");
    }
  }

  /// ================================================================
  /// 5) Детальный результат
  /// ================================================================
  static Future<ScanResult> getScanById(int id) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Нет токена.");
    }

    final uri = Uri.parse("$baseUrl/scan/$id");
    final res = await http.get(uri, headers: {"Authorization": "Bearer $token"});

    if (res.statusCode == 200) {
      return ScanResult.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      throw Exception("Проверка не найдена.");
    } else {
      throw Exception("Ошибка загрузки: ${res.statusCode} ${res.body}");
    }
  }
}