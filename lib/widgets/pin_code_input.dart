import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class PinCodeInput extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final String? errorText;
  final bool enabled;

  const PinCodeInput({
    super.key,
    required this.onCompleted,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<PinCodeInput> createState() => PinCodeInputState();
}

class PinCodeInputState extends State<PinCodeInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void clear() {
    _controller.clear();
    setState(() {});
    _focusNode.requestFocus();
  }

  void _onChanged(String value) {
    final normalized = value.replaceAll(RegExp(r'\D'), '');
    if (normalized != value) {
      _controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    setState(() {});
    if (normalized.length == 4) {
      widget.onCompleted(normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text;

    return Column(
      children: [
        GestureDetector(
          onTap: widget.enabled ? _focusNode.requestFocus : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: _onChanged,
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    _PinCell(
                      filled: i < value.length,
                      focused: widget.enabled && i == value.length,
                      hasError: widget.errorText != null,
                    ),
                    if (i != 3) const SizedBox(width: 12),
                  ],
                ],
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: widget.errorText == null
              ? const SizedBox(height: 22)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.errorText!,
                    key: ValueKey(widget.errorText),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _PinCell extends StatelessWidget {
  final bool filled;
  final bool focused;
  final bool hasError;

  const _PinCell({
    required this.filled,
    required this.focused,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFDC2626)
        : focused
            ? OySynAuthTokens.primaryBlue
            : OySynAuthTokens.fieldBorder;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 58,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: focused ? 1.8 : 1.2),
        boxShadow: [
          if (focused)
            BoxShadow(
              color: OySynAuthTokens.shadowBlue.withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: filled ? 14 : 7,
          height: filled ? 14 : 7,
          decoration: BoxDecoration(
            color: filled ? OySynAuthTokens.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: filled
                ? null
                : Border.all(color: OySynAuthTokens.divider, width: 1.2),
          ),
        ),
      ),
    );
  }
}
