import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../services/qr_login_service.dart';
import '../../../theme/app_theme.dart';

class QrPage extends StatefulWidget {
  const QrPage({super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  final MobileScannerController _scannerController = MobileScannerController();

  String? _qrToken;
  String? _message;
  bool _busy = false;
  bool _handledScan = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handledScan || _busy) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        rawValue = value;
        break;
      }
    }
    if (rawValue == null) return;

    final token = QrLoginService.tokenFromQr(rawValue);
    if (token == null || token.isEmpty) return;

    _handledScan = true;
    _scannerController.stop();
    setState(() {
      _qrToken = token;
      _message = null;
    });
  }

  Future<void> _approve() async {
    final token = _qrToken;
    if (token == null || _busy) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await QrLoginService.approve(token);
      if (!mounted) return;
      setState(() {
        _qrToken = null;
        _message = 'Вход в веб подтвержден';
      });
    } catch (error) {
      if (!mounted) return;
      setState(
          () => _message = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reject() async {
    final token = _qrToken;
    if (token == null || _busy) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await QrLoginService.reject(token);
      if (!mounted) return;
      setState(() {
        _qrToken = null;
        _message = 'Вход в веб отклонен';
      });
    } catch (error) {
      if (!mounted) return;
      setState(
          () => _message = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _scanAgain() {
    setState(() {
      _qrToken = null;
      _message = null;
      _handledScan = false;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
      children: [
        Text(
          'OySyn QR',
          style: OySynTextStyles.sectionTitle,
        ),
        const SizedBox(height: 20),
        _ScannerPanel(
          controller: _scannerController,
          active: _qrToken == null,
          onDetect: _onDetect,
        ),
        const SizedBox(height: 16),
        _QrActionPanel(
          qrToken: _qrToken,
          message: _message,
          busy: _busy,
          onApprove: _approve,
          onReject: _reject,
          onScanAgain: _scanAgain,
        ),
      ],
    );
  }
}

class _ScannerPanel extends StatelessWidget {
  const _ScannerPanel({
    required this.controller,
    required this.active,
    required this.onDetect,
  });

  final MobileScannerController controller;
  final bool active;
  final void Function(BarcodeCapture capture) onDetect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              onDetect: onDetect,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.72),
                  width: 2,
                ),
              ),
            ),
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: active
                        ? OySynAuthTokens.primaryBlue
                        : OySynAuthTokens.divider,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrActionPanel extends StatelessWidget {
  const _QrActionPanel({
    required this.qrToken,
    required this.message,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onScanAgain,
  });

  final String? qrToken;
  final String? message;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    final token = qrToken;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OySynAuthTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OySynAuthTokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            token == null ? Icons.qr_code_scanner_rounded : Icons.login_rounded,
            color: OySynAuthTokens.primaryBlue,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            token == null
                ? 'Наведите камеру на QR-код входа'
                : 'Подтвердить вход в веб?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: OySynAuthTokens.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OySynAuthTokens.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (token == null)
            OutlinedButton.icon(
              onPressed: busy ? null : onScanAgain,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Сканировать'),
            )
          else ...[
            FilledButton.icon(
              onPressed: busy ? null : onApprove,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('Подтвердить'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: busy ? null : onReject,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Отклонить'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: busy ? null : onScanAgain,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Сканировать другой код'),
            ),
          ],
        ],
      ),
    );
  }
}
