import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/core/utils/pk_phone.dart';

/// Feeds [text] into the Sign In field one keystroke at a time, exactly
/// the way the field's onChanged does (write back only if it differs).
String typeInto(String text) {
  var field = '';
  for (final ch in text.split('')) {
    final next = PkPhone.formatLocalFull(field + ch);
    field = next;
  }
  return field;
}

void main() {
  group('PkPhone.isValid — accepted', () {
    for (final s in [
      '03001234567', // TEST 1
      '0300 1234567', // TEST 2
      '0300-1234567',
      '+923001234567', // TEST 3
      '+92 300 1234567',
      '00923001234567',
      '923001234567',
      '3001234567', // subscriber-only (chip-paired fields)
    ]) {
      test(s, () => expect(PkPhone.isValid(s), isTrue));
    }
  });

  group('PkPhone.isValid — rejected', () {
    for (final s in [
      '',
      '   ',
      'abc',
      '0300123456', // too short
      '030012345678', // too long — must NOT be trimmed into validity
      '03001234567890',
      '04001234567', // not a 03 mobile prefix
      '02101234567', // landline-style
      '+924001234567',
      'saithcommissionshop@gmail.com', // TEST 5 style: not a phone
    ]) {
      test(s.isEmpty ? '(empty)' : s, () => expect(PkPhone.isValid(s), isFalse));
    }
  });

  group('PkPhone.toE164 — one canonical form', () {
    for (final s in [
      '03001234567',
      '0300 1234567',
      '+923001234567',
      '+92 300 1234567',
      '00923001234567',
    ]) {
      test(s, () => expect(PkPhone.toE164(s), '+923001234567'));
    }
    test('never produces the extra-0 form', () {
      expect(PkPhone.toE164('03001234567'), isNot(contains('+920')));
    });
    test('invalid -> null', () => expect(PkPhone.toE164('abc'), isNull));
  });

  group('PkPhone.formatLocalFull — Sign In field', () {
    final cases = <String, String>{
      '0': '0', // the first keystroke must stay visible
      '03': '03',
      '0300': '0300',
      '03001': '0300 1',
      '03001234567': '0300 1234567',
      '030012345678999': '0300 1234567', // capped at 11 digits
      '0300 1234567': '0300 1234567',
      '+923001234567': '+92 300 1234567',
      '+92': '+92',
      '+9': '+9',
      '00923001234567': '+92 300 1234567',
      '3001234567': '3001234567', // left alone, still valid
      '': '',
    };
    cases.forEach((input, expected) {
      test('"$input" -> "$expected"',
          () => expect(PkPhone.formatLocalFull(input), expected));
    });

    test('an email is never touched', () {
      for (final e in [
        's',
        'saith',
        'saithcommissionshop@gmail.com',
        'owner@example.com',
        'admin@mandishop.pk',
      ]) {
        expect(PkPhone.formatLocalFull(e), e);
      }
    });

    test('TEST 4: an email can be typed keystroke by keystroke', () {
      const email = 'saithcommissionshop@gmail.com';
      expect(typeInto(email), email);
    });

    test('a phone can be typed keystroke by keystroke, starting with 0', () {
      expect(PkPhone.formatLocalFull('0'), '0');
      expect(typeInto('03001234567'), '0300 1234567');
    });
  });

  group('PkPhone.formatAsTyped — chip-paired fields', () {
    final cases = <String, String>{
      '3001234567': '300 1234567',
      '03001234567': '300 1234567',
      '+923001234567': '300 1234567',
      '3': '3',
      '30012345678999': '300 1234567',
      '': '',
    };
    cases.forEach((input, expected) {
      test('"$input" -> "$expected"',
          () => expect(PkPhone.formatAsTyped(input), expected));
    });
  });

  test('toLocalDisplay', () {
    expect(PkPhone.toLocalDisplay('+923001234567'), '0300 1234567');
  });

  test('looksLikePhone', () {
    expect(PkPhone.looksLikePhone('0300 123'), isTrue);
    expect(PkPhone.looksLikePhone('+92 300'), isTrue);
    expect(PkPhone.looksLikePhone('a@b.com'), isFalse);
    expect(PkPhone.looksLikePhone(''), isFalse);
  });
}
