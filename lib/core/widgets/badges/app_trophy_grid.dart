import 'package:flutter/material.dart';
import '../../../features/rank/models/trophy_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';

class _TrophyStyle {
  const _TrophyStyle(this.glyph, this.gradient);

  final String glyph;
  final List<Color> gradient;
}

// Glyphs/gradients match the mockup's own BADGES fixture verbatim (numerals
// are the actual thresholds: 7/14-day streaks, 10 judged proofs).
const _trophyStyles = {
  'premiere_flamme': _TrophyStyle('7', [
    AppColors.emberBright,
    AppColors.emberDeep,
  ]),
  'juge_integre': _TrophyStyle('10', [Color(0xFFB3A8FF), Color(0xFF6B5CE0)]),
  'mise_tenue': _TrophyStyle('✓', [Color(0xFFE2FF8A), Color(0xFF8DB82A)]),
  'semaine_de_fer': _TrophyStyle('14', [
    AppColors.emberLight,
    AppColors.emberDeep,
  ]),
  'escouade': _TrophyStyle('4', [AppColors.violet, Color(0xFF4A3FA8)]),
  'obsidienne': _TrophyStyle('◆', [
    AppColors.obsidienneLight,
    AppColors.obsidienneDark,
  ]),
};

/// 3-column grid of trophy tiles — earned trophies get their themed
/// gradient badge and colored name, unearned ones a flat greyscale fill and
/// muted text, matching the mockup's profile trophy grid.
class AppTrophyGrid extends StatelessWidget {
  const AppTrophyGrid({super.key, required this.trophies});

  final List<TrophyItem> trophies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trophies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) => _TrophyTile(trophy: trophies[index]),
    );
  }
}

class _TrophyTile extends StatelessWidget {
  const _TrophyTile({required this.trophy});

  final TrophyItem trophy;

  @override
  Widget build(BuildContext context) {
    final style = _trophyStyles[trophy.key];
    final gradient = trophy.earned && style != null
        ? style.gradient
        : [AppColors.surfaceContainerHighest, AppColors.surfaceContainerHighest];
    final glyph = style?.glyph ?? '?';
    final nameColor = trophy.earned ? AppColors.primary : AppColors.outlineFaint;
    final glyphColor = trophy.earned ? AppColors.onPrimary : AppColors.outlineFaint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipPath(
            clipper: const _StaticDiamondClipper(),
            child: Container(
              width: 40,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              child: Text(
                glyph,
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: glyphColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trophy.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: nameColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            trophy.description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.3,
              color: AppColors.outlineFaint,
            ),
          ),
        ],
      ),
    );
  }
}

// AppRankBadge's clipper is private; a matching one is redeclared here
// rather than reusing a StatelessWidget sized only for rank badges.
class _StaticDiamondClipper extends CustomClipper<Path> {
  const _StaticDiamondClipper();

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
