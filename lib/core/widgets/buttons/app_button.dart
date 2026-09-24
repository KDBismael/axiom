import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_effects.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, danger, amber }

/// The thick-pressable button from the "Ndeli — Arène" design system.
///
/// `primary`/`danger`/`amber` are flat-filled CTAs sitting on a solid drop
/// shadow that collapses on press (see [AppPressable]). `secondary` is the
/// flat outlined dark button used for Google/Apple and other binary choices.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final bool loading;

  static const minHeight = 58.0;
  static const _padding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;
    final disabled = effectiveOnPressed == null;

    switch (variant) {
      case AppButtonVariant.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: minHeight,
          child: Material(
            color: AppColors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.interactiveRadius,
              side: BorderSide(color: AppColors.outlineVariantStrong),
            ),
            child: InkWell(
              onTap: effectiveOnPressed,
              borderRadius: AppRadii.interactiveRadius,
              child: Padding(
                padding: _padding,
                child: Center(
                  child: _content(
                    textStyle: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: disabled ? AppColors.outlineFaint : AppColors.primary,
                    ),
                    iconColor: disabled ? AppColors.outlineFaint : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
      case AppButtonVariant.amber:
        final (fill, shadow, onFill) = switch (variant) {
          AppButtonVariant.danger => (AppColors.error, AppColors.errorShadow, const Color(0xFF1A0505)),
          AppButtonVariant.amber => (AppColors.amber, AppColors.amberShadow, const Color(0xFF1A1405)),
          _ => (AppColors.volt, AppColors.voltShadow, AppColors.onPrimary),
        };
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: minHeight,
          child: AppPressable(
            color: disabled ? AppColors.surfaceContainerHighest : fill,
            shadowColor: disabled ? const Color(0xFF0A0A0C) : shadow,
            onTap: effectiveOnPressed,
            enabled: !disabled,
            child: Padding(
              padding: _padding,
              child: Center(
                child: _content(
                  textStyle: AppTypography.labelMd.copyWith(
                    fontFamily: 'Unbounded',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.05 * 13,
                    color: disabled ? AppColors.outlineFaint : onFill,
                  ),
                  iconColor: disabled ? AppColors.outlineFaint : onFill,
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _content({required TextStyle textStyle, required Color iconColor}) {
    if (loading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
      );
    }
    final text = Text(label, style: textStyle);
    if (leadingIcon == null && trailingIcon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18, color: iconColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(label, style: textStyle, overflow: TextOverflow.ellipsis),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18, color: iconColor),
        ],
      ],
    );
  }
}
