/// Pakistani CNIC: 13 digits, displayed as XXXXX-XXXXXXX-X.
class PkCnic {
  /// Digits only, NOT truncated — an over-long value must fail [isValid].
  static String digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');

  /// Live-formats as the user types (display caps at 13 digits).
  static String formatAsTyped(String input) {
    var d = digitsOnly(input);
    if (d.length > 13) d = d.substring(0, 13);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 5 || i == 12) b.write('-');
      b.write(d[i]);
    }
    return b.toString();
  }

  static bool isValid(String input) => digitsOnly(input).length == 13;

  /// Shape for storage if a backend wants digits only: "3410253860221".
  static String normalize(String input) => digitsOnly(input);

  /// 35202-*******-1 — use everywhere except the edit/registration screen.
  static String mask(String cnicOrDigits) {
    final d = digitsOnly(cnicOrDigits);
    if (d.length != 13) return cnicOrDigits;
    return '${d.substring(0, 5)}-*******-${d.substring(12)}';
  }

  static const errorMessage = 'Enter a valid 13-digit CNIC.';
}
