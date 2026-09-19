/// Pakistani CNIC (Computerized National Identity Card) formatting,
/// validation and masking. Format: XXXXX-XXXXXXX-X (13 digits total).
class PkCnic {
  static String _digitsOnly(String input) {
    final d = input.replaceAll(RegExp(r'\D'), '');
    return d.length > 13 ? d.substring(0, 13) : d;
  }

  /// Live-formats input as the user types: 3520212345671 → 35202-1234567-1.
  /// Use as a TextField's onChanged, feeding the result back into the
  /// controller.
  static String formatAsTyped(String input) {
    final d = _digitsOnly(input);
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 5 || i == 12) buf.write('-');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  static bool isValid(String input) => _digitsOnly(input).length == 13;

  /// Stores/transmits as plain 13 digits with the standard dashes — never
  /// store or display this outside a secure editing/registration screen;
  /// use [mask] for any other context.
  static String normalize(String input) => formatAsTyped(input);

  /// 35202-*******-1 — use this everywhere except the registration/profile
  /// edit screen itself.
  static String mask(String cnicOrDigits) {
    final d = _digitsOnly(cnicOrDigits);
    if (d.length != 13) return cnicOrDigits;
    return '${d.substring(0, 5)}-*******-${d.substring(12, 13)}';
  }

  static const errorMessage = 'Enter a valid 13-digit CNIC.';
}
