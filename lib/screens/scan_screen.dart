import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../services/scan_service.dart';
import '../models/scan_result.dart';
import 'scan_details_screen.dart';
import 'text_input_screen.dart';

class ScanScreen extends StatefulWidget {
  final void Function(ScanResult)? onScanCompleted;

  const ScanScreen({super.key, this.onScanCompleted});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _lastError;

  // ============================================================================
  //                        CAMERA / GALLERY (OCR)
  // ============================================================================
  Future<void> _pickAndScan(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
        _lastError = null;
      });

      final picked = await _picker.pickImage(source: source);
      if (picked == null) {
        setState(() => _isLoading = false);
        return;
      }

      final file = File(picked.path);

      // OCR
      final text = await ScanService.uploadImageForOCR(file);
      if (text.trim().isEmpty) {
        throw Exception("Не удалось распознать текст");
      }

      // AI-check
      final ScanResult result = await ScanService.createScan(text);

      if (widget.onScanCompleted != null) {
        widget.onScanCompleted!(result);
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanDetailsScreen(
            result: result,
            loadFromBackend: false,
          ),
        ),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _lastError = e.toString();
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  // ============================================================================
  //                        UPLOAD PDF / DOC / DOCX
  // ============================================================================
  Future<void> _pickDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _lastError = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      final file = File(result.files.single.path!);

      final ScanResult scan = await ScanService.uploadDocumentForScan(file);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanDetailsScreen(
            result: scan,
            loadFromBackend: false,
          ),
        ),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _lastError = e.toString();
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  // ============================================================================
  //                                UI HELPERS
  // ============================================================================
  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Colors.blue.shade700),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }

  // ============================================================================
  //                                 UI
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      appBar: AppBar(
        title: const Text("ScanAI — Проверка текста"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text("Обработка..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.document_scanner_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Выберите способ проверки",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ===================== GRID OF ACTIONS =====================
                  SizedBox(
                    height: 360, // оптимальная высота под 4 карточки
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.95,
                      children: [
                        _buildOptionCard(
                          icon: Icons.photo_camera_rounded,
                          label: "Сканировать\nс камеры",
                          onTap: () => _pickAndScan(ImageSource.camera),
                        ),
                        _buildOptionCard(
                          icon: Icons.photo_library_rounded,
                          label: "Выбрать\nиз галереи",
                          onTap: () => _pickAndScan(ImageSource.gallery),
                        ),
                        _buildOptionCard(
                          icon: Icons.upload_file_rounded,
                          label: "Загрузить файл\n(PDF / DOCX)",
                          onTap: _pickDocument,
                        ),
                        _buildOptionCard(
                          icon: Icons.edit_note_rounded,
                          label: "Вставить текст\nвручную",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TextInputScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_lastError != null)
                    Text(
                      _lastError!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
    );
  }
}