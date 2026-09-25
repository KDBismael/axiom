/// `GET /me/trophies` item — one of the 6 fixed trophies, earned or not.
class TrophyItem {
  const TrophyItem({
    required this.key,
    required this.name,
    required this.description,
    required this.earned,
    this.awardedAt,
  });

  final String key;
  final String name;
  final String description;
  final bool earned;
  final DateTime? awardedAt;

  factory TrophyItem.fromJson(Map<String, dynamic> json) {
    return TrophyItem(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      earned: json['earned'] as bool,
      awardedAt: json['awardedAt'] == null
          ? null
          : DateTime.parse(json['awardedAt'] as String),
    );
  }
}
