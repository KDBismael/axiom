class Country {
  const Country({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.localLength,
    required this.example,
  });

  final String code;
  final String name;
  final String dialCode;

  /// Digits in a national number (after the dial code), per the
  /// country's current numbering plan.
  final int localLength;

  /// A well-formed national number, shown as the field's hint.
  final String example;

  bool isValidLocalNumber(String input) =>
      input.replaceAll(RegExp(r'[^0-9]'), '').length == localLength;

  static Country? fromDialCode(String dialCode) {
    for (final country in xofZoneCountries) {
      if (country.dialCode == dialCode) return country;
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is Country && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// The eight UEMOA (XOF-zone) countries: Côte d'Ivoire first — the app's
/// primary market — then the others. Lengths follow each country's
/// current plan (Côte d'Ivoire 10 digits since 2021, Bénin 10 since 2024).
const xofZoneCountries = <Country>[
  Country(
    code: 'CI',
    name: "Côte d'Ivoire",
    dialCode: '+225',
    localLength: 10,
    example: '07 01 02 03 04',
  ),
  Country(
    code: 'SN',
    name: 'Sénégal',
    dialCode: '+221',
    localLength: 9,
    example: '77 123 45 67',
  ),
  Country(
    code: 'ML',
    name: 'Mali',
    dialCode: '+223',
    localLength: 8,
    example: '76 12 34 56',
  ),
  Country(
    code: 'BF',
    name: 'Burkina Faso',
    dialCode: '+226',
    localLength: 8,
    example: '70 12 34 56',
  ),
  Country(
    code: 'BJ',
    name: 'Bénin',
    dialCode: '+229',
    localLength: 10,
    example: '01 97 12 34 56',
  ),
  Country(
    code: 'TG',
    name: 'Togo',
    dialCode: '+228',
    localLength: 8,
    example: '90 12 34 56',
  ),
  Country(
    code: 'NE',
    name: 'Niger',
    dialCode: '+227',
    localLength: 8,
    example: '90 12 34 56',
  ),
  Country(
    code: 'GW',
    name: 'Guinée-Bissau',
    dialCode: '+245',
    localLength: 9,
    example: '955 123 456',
  ),
];

class PhoneParts {
  const PhoneParts({required this.country, required this.localNumber});

  final Country country;
  final String localNumber;
}

/// Splits a full phone number (e.g. `+2250700000000`) into its XOF-zone
/// country and the remaining local digits. Falls back to the first
/// XOF-zone country (Côte d'Ivoire) when [phone] is null/empty or its
/// dial code isn't recognized.
PhoneParts splitPhoneNumber(String? phone) {
  if (phone == null || phone.isEmpty) {
    return PhoneParts(country: xofZoneCountries.first, localNumber: '');
  }
  final byLongestDialCode = [...xofZoneCountries]
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
  for (final country in byLongestDialCode) {
    if (phone.startsWith(country.dialCode)) {
      return PhoneParts(
        country: country,
        localNumber: phone.substring(country.dialCode.length),
      );
    }
  }
  return PhoneParts(country: xofZoneCountries.first, localNumber: phone);
}
