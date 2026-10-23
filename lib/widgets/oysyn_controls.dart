import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

double oysynSystemBottomInset(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  return math.max(
    mediaQuery.viewPadding.bottom,
    mediaQuery.systemGestureInsets.bottom,
  );
}

double oysynInteractiveBottomInset(BuildContext context) {
  return math.max(
    MediaQuery.viewInsetsOf(context).bottom,
    oysynSystemBottomInset(context),
  );
}

Future<bool?> showOySynActionDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required IconData icon,
  IconData confirmIcon = Icons.check_rounded,
  bool destructive = false,
}) {
  final accent =
      destructive ? const Color(0xFFDF3E48) : OySynAuthTokens.primaryBlue;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: OySynTextStyles.sectionTitle,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: OySynAuthTokens.textMuted,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Отмена'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: destructive
                        ? FilledButton.styleFrom(backgroundColor: accent)
                        : null,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    icon: Icon(confirmIcon, size: 19),
                    label: Text(confirmLabel),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<String?> showOySynTextInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  String initialValue = '',
  IconData icon = Icons.folder_outlined,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _OySynTextInputDialog(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      icon: icon,
    ),
  );
}

class _OySynTextInputDialog extends StatefulWidget {
  final String title;
  final String label;
  final String confirmLabel;
  final String initialValue;
  final IconData icon;

  const _OySynTextInputDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.initialValue,
    required this.icon,
  });

  @override
  State<_OySynTextInputDialog> createState() => _OySynTextInputDialogState();
}

class _OySynTextInputDialogState extends State<_OySynTextInputDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Введите название');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: OySynAuthTokens.primaryBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.title, style: OySynTextStyles.sectionTitle),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 512,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: _error,
              counterText: '',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded, size: 19),
                    label: Text(widget.confirmLabel),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OySynChoice<T> {
  final T value;
  final String label;
  final IconData? icon;

  const OySynChoice(this.value, this.label, {this.icon});
}

Future<T?> showOySynChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<OySynChoice<T>> choices,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      margin: EdgeInsets.only(bottom: oysynSystemBottomInset(context)),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .72,
      ),
      decoration: const BoxDecoration(
        color: OySynAuthTokens.appBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFC9D1E2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 17, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: OySynAuthTokens.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Закрыть',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                20 + oysynSystemBottomInset(context),
              ),
              itemCount: choices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final choice = choices[index];
                final active = choice.value == selected;
                return Material(
                  color: active ? const Color(0xFFEAF0FF) : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(choice.value),
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: active
                              ? const Color(0xFF9DB6FA)
                              : OySynAuthTokens.divider,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          if (choice.icon != null) ...[
                            Icon(
                              choice.icon,
                              size: 20,
                              color: active
                                  ? OySynAuthTokens.primaryBlue
                                  : OySynAuthTokens.textMuted,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              choice.label,
                              style: TextStyle(
                                color: OySynAuthTokens.textDark,
                                fontSize: 15,
                                fontWeight:
                                    active ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (active)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: OySynAuthTokens.primaryBlue,
                              size: 21,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class OySynSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const OySynSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color:
                value ? OySynAuthTokens.primaryBlue : const Color(0xFFD7DDEA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
