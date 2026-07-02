import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

enum AppButtonVariant { primary, lustre, secondary }

/// The "Instrument" style button from the Monolith Architect design system.
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

  static const _minHeight = 52.0;
  static const _padding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;

    switch (variant) {
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(fullWidth ? double.infinity : 88, _minHeight),
            padding: _padding,
            side: BorderSide(color: AppColors.outline20),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.interactiveRadius),
          ),
          child: _content(),
        );
      case AppButtonVariant.lustre:
        return _LustreButton(
          label: label,
          onPressed: effectiveOnPressed,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          fullWidth: fullWidth,
          loading: loading,
        );
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(fullWidth ? double.infinity : 88, _minHeight),
            padding: _padding,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppRadii.interactiveRadius),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.surfaceContainerHighest;
              }
              if (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered)) {
                return AppColors.primaryFixedDim;
              }
              return AppColors.emerald;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.outline;
              }
              return AppColors.primary;
            }),
          ),
          child: _content(),
        );
    }
  }

  Widget _content() {
    if (loading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      );
    }
    final text = Text(label, style: AppTypography.labelMd);
    if (leadingIcon == null && trailingIcon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(label, style: AppTypography.labelMd, overflow: TextOverflow.ellipsis),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18),
        ],
      ],
    );
  }
}

/// Optional premium gradient CTA treatment — not expressible via
/// [ElevatedButton.styleFrom] since it needs a [LinearGradient] fill.
class _LustreButton extends StatelessWidget {
  const _LustreButton({
    required this.label,
    required this.onPressed,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.fullWidth,
    required this.loading,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppButton._minHeight,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.interactiveRadius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadii.interactiveRadius,
            gradient: disabled
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryFixed, AppColors.primaryFixedDim],
                  ),
            color: disabled ? AppColors.surfaceContainerHighest : null,
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadii.interactiveRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leadingIcon != null) ...[
                            Icon(leadingIcon, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (trailingIcon != null) ...[
                            const SizedBox(width: 8),
                            Icon(trailingIcon, size: 18, color: AppColors.primary),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
