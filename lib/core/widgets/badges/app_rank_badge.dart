import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// The "diamond" hexagon rank badge: a metallic gradient fill (per tier)
/// clipped to `polygon(50% 0,100% 25%,100% 75%,50% 100%,0 75%,0 25%)`, with
/// the sub-level roman numeral centered inside.
class AppRankBadge extends StatelessWidget {
  const AppRankBadge({
    super.key,
    required this.tier,
    required this.subLevel,
    this.width = 40,
    this.height = 44,
    this.fontSize = 13,
  });

  final String tier;
  final String subLevel;
  final double width;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.rankTierGradient(tier);
    return ClipPath(
      clipper: _DiamondClipper(),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: Text(
          subLevel,
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _DiamondClipper extends CustomClipper<Path> {
  const _DiamondClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
