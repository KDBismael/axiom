import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/profile/models/country.dart';

void main() {
  group('xofZoneCountries', () {
    test('includes Côte d\'Ivoire first, as the app\'s primary market', () {
      expect(xofZoneCountries.first.dialCode, '+225');
      expect(xofZoneCountries.first.name, "Côte d'Ivoire");
    });

    test('every entry has a unique dial code', () {
      final dialCodes = xofZoneCountries.map((c) => c.dialCode).toSet();
      expect(dialCodes.length, xofZoneCountries.length);
    });
  });

  group('Country.fromDialCode', () {
    test('matches a known dial code', () {
      final country = Country.fromDialCode('+221');
      expect(country?.name, 'Sénégal');
    });

    test('returns null for an unknown dial code', () {
      expect(Country.fromDialCode('+1'), isNull);
    });
  });

  group('splitPhoneNumber', () {
    test('splits a full E.164-ish number into country + local digits', () {
      final result = splitPhoneNumber('+2250700000000');
      expect(result.country.dialCode, '+225');
      expect(result.localNumber, '0700000000');
    });

    test('defaults to the first XOF-zone country when phone is null', () {
      final result = splitPhoneNumber(null);
      expect(result.country, xofZoneCountries.first);
      expect(result.localNumber, '');
    });

    test('defaults to the first XOF-zone country when the dial code is unrecognized', () {
      final result = splitPhoneNumber('+19995551234');
      expect(result.country, xofZoneCountries.first);
      expect(result.localNumber, '+19995551234');
    });
  });
}
