import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/core/utils/pk_cnic.dart';

void main() {
  test('formats 13 digits as XXXXX-XXXXXXX-X', () {
    expect(PkCnic.formatAsTyped('3410253860221'), '34102-5386022-1');
  });

  test('formats progressively while typing', () {
    expect(PkCnic.formatAsTyped('34102'), '34102');
    expect(PkCnic.formatAsTyped('341025'), '34102-5');
    expect(PkCnic.formatAsTyped('341025386022'), '34102-5386022');
  });

  test('strips junk and caps display at 13 digits', () {
    expect(PkCnic.formatAsTyped('34102-5386022-1abc'), '34102-5386022-1');
    expect(PkCnic.formatAsTyped('341025386022199999'), '34102-5386022-1');
  });

  test('valid: exactly 13 digits, dashed or not', () {
    expect(PkCnic.isValid('34102-5386022-1'), isTrue);
    expect(PkCnic.isValid('3410253860221'), isTrue);
  });

  test('invalid: wrong length, letters, empty — and over-long is NOT trimmed valid', () {
    expect(PkCnic.isValid('341025386022'), isFalse); // 12
    expect(PkCnic.isValid('34102538602212'), isFalse); // 14
    expect(PkCnic.isValid('abc'), isFalse);
    expect(PkCnic.isValid(''), isFalse);
  });

  test('normalize gives digits only', () {
    expect(PkCnic.normalize('34102-5386022-1'), '3410253860221');
  });

  test('mask hides the middle 7 digits', () {
    expect(PkCnic.mask('34102-5386022-1'), '34102-*******-1');
    expect(PkCnic.mask('3410253860221'), '34102-*******-1');
    expect(PkCnic.mask('123'), '123'); // not a full CNIC: unchanged
  });
}
