import 'package:flutter/material.dart';

/// Dismisses the software keyboard when a pointer is pressed outside the
/// currently focused editable area. This also works when the target is a
/// button, where a parent GestureDetector would lose the gesture arena.
class KeyboardDismissArea extends StatelessWidget {
  final Widget child;

  const KeyboardDismissArea({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final focus = FocusManager.instance.primaryFocus;
        if (focus == null) return;

        final renderObject = focus.context?.findRenderObject();
        if (renderObject is RenderBox && renderObject.hasSize) {
          final localPosition = renderObject.globalToLocal(event.position);
          if (renderObject.paintBounds.contains(localPosition)) return;
        }

        focus.unfocus();
      },
      child: child,
    );
  }
}
