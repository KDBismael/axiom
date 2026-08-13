import 'package:flutter/material.dart';

/// Dismisses the active software keyboard when a pointer is pressed outside
/// the currently focused input. Kept at the app root so every form behaves
/// consistently without each screen needing its own GestureDetector.
class KeyboardDismissOnTap extends StatelessWidget {
  const KeyboardDismissOnTap({super.key, required this.child});

  final Widget child;

  void _handlePointerDown(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return;

    final renderObject = focus.context?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final localPosition = renderObject.globalToLocal(event.position);
      if (renderObject.size.contains(localPosition)) return;
    }
    focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: child,
    );
  }
}
