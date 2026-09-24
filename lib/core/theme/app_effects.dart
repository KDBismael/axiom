import 'package:flutter/material.dart';
import 'app_radii.dart';

/// The signature "thick pressable" surface of the "Ndeli — Arène" design
/// system: a flat-filled shape sitting on a solid, blur-less drop shadow
/// that collapses — and the shape itself slides down into it — on press.
/// Used for every filled button (primary/danger/amber CTAs) and the square
/// icon-buttons (back arrow, stepper +/-, quest quick-actions).
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    required this.color,
    required this.shadowColor,
    this.onTap,
    this.borderRadius,
    this.shadowThickness = 5,
    this.border,
    this.enabled = true,
  });

  final Widget child;
  final Color color;
  final Color shadowColor;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  /// Vertical drop of the shadow (and the press travel distance) in logical
  /// pixels. The mockup uses 5 for full-width CTAs, 3–4 for smaller
  /// square icon-buttons.
  final double shadowThickness;
  final BoxBorder? border;
  final bool enabled;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_interactive) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadii.interactiveRadius;
    final restingShadow = widget.shadowThickness;
    final pressedShadow = restingShadow > 2 ? 1.0 : restingShadow;
    final shadowNow = _pressed ? pressedShadow : restingShadow;
    final travel = restingShadow - shadowNow;

    return GestureDetector(
      onTap: _interactive ? widget.onTap : null,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, travel, 0),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: radius,
          border: widget.border,
          boxShadow: [
            BoxShadow(color: widget.shadowColor, offset: Offset(0, shadowNow)),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
