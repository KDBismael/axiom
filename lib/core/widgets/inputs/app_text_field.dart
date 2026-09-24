import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

/// The boxed, labeled input field from the "Ndeli — Arène" design system:
/// an uppercase Geist-Mono eyebrow label above a 52px filled+bordered field
/// with a volt focus border. Replaces the per-screen `_fieldDecoration`/
/// `_UnderlineField` duplicates the auth views used to hand-roll.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.allowObscureToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofillHints,
    this.suffix,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final bool allowObscureToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final Iterable<String>? autofillHints;

  /// Custom trailing widget. Ignored when [allowObscureToggle] is true.
  final Widget? suffix;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    Widget? suffix = widget.suffix;
    if (widget.allowObscureToggle) {
      suffix = IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.outlineMuted,
          size: 20,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: AppTypography.labelMd.copyWith(fontSize: 11, color: AppColors.outlineMuted),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: TextField(
            controller: widget.controller,
            obscureText: widget.allowObscureToggle ? _obscured : widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            enabled: widget.enabled,
            autofillHints: widget.autofillHints,
            style: const TextStyle(fontFamily: 'Geist', fontSize: 15, color: AppColors.primary),
            cursorColor: AppColors.volt,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                color: AppColors.outlineFaint,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: AppRadii.interactiveRadius,
                borderSide: const BorderSide(color: AppColors.outlineVariantStrong),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.interactiveRadius,
                borderSide: const BorderSide(color: AppColors.outlineVariantStrong),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.interactiveRadius,
                borderSide: const BorderSide(color: AppColors.outlineVariantStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.interactiveRadius,
                borderSide: const BorderSide(color: AppColors.volt),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
