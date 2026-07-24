class Country {
  const Country({required this.code, required this.name, required this.dialCode});

  final String code;
  final String name;
  final String dialCode;

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

/// Côte d'Ivoire first — the app's primary market — followed by
/// neighboring XOF-zone countries.
const xofZoneCountries = <Country>[
  Country(code: 'CI', name: "Côte d'Ivoire", dialCode: '+225'),
  Country(code: 'SN', name: 'Sénégal', dialCode: '+221'),
  Country(code: 'ML', name: 'Mali', dialCode: '+223'),
  Country(code: 'BF', name: 'Burkina Faso', dialCode: '+226'),
  Country(code: 'BJ', name: 'Bénin', dialCode: '+229'),
  Country(code: 'TG', name: 'Togo', dialCode: '+228'),
  Country(code: 'NE', name: 'Niger', dialCode: '+227'),
  Country(code: 'GW', name: 'Guinée-Bissau', dialCode: '+245'),
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
      return PhoneParts(country: country, localNumber: phone.substring(country.dialCode.length));
    }
  }
  return PhoneParts(country: xofZoneCountries.first, localNumber: phone);
}
