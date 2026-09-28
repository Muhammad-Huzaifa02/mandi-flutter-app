/// Pakistani mobile number formatting, validation and normalization.
///
/// Two display conventions exist on purpose:
///
/// - [formatAsTyped] — for fields paired with a separate visible "🇵🇰 +92"
///   chip (registration, forgot-password, add-staff). The chip already
///   shows the country code, so the field holds only the 10-digit
///   subscriber number with NO leading 0 ("300 9099500"). Adding the 0
///   back there would produce "+92 0300…", which is wrong.
///
/// - [formatLocalFull] — for the unified Sign In field, which has no chip
///   and accepts a phone number OR an email. It leaves anything that is
///   not clearly a phone number untouched (so emails can be typed
///   normally) and formats phone input as "0300 0000000" or
///   "+92 300 0000000".
///
/// [isValid] / [toE164] accept every common way of writing the same
/// number (03001234567, 0300 1234567, +92 300 1234567, 00923001234567…)
/// and normalize to +923001234567, so equivalent inputs are always the
/// same account.
class PkPhone {
  /// Subscriber digits only — no country code, no trunk 0 (e.g.
  /// "3001234567"). Deliberately NOT truncated: over-long input must be
  /// rejected by [isValid], not silently trimmed into validity. Only the
  /// display formatters cap length.
  static String _subscriberDigits(String input) {
    var d = input.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0092')) {
      d = d.substring(4);
    } else if (d.startsWith('92') && d.length > 10) {
      d = d.substring(2);
    } else if (d.startsWith('0')) {
      d = d.substring(1);
    }
    return d;
  }

  /// True if [input] is made only of characters a phone number can
  /// contain (digits, spaces, +, -, parentheses). Anything with a letter
  /// or an "@" is treated as an email, never reformatted.
  static bool looksLikePhone(String input) {
    final t = input.trim();
    return t.isNotEmpty && RegExp(r'^[0-9+\s\-()]+$').hasMatch(t);
  }

  /// For fields paired with a separate "+92" chip: "3XX XXXXXXX".
  static String formatAsTyped(String input) {
    var d = _subscriberDigits(input);
    if (d.length > 10) d = d.substring(0, 10);
    if (d.length <= 3) return d;
    return '${d.substring(0, 3)} ${d.substring(3)}';
  }

  /// For the chip-less Sign In field. Use as onChanged, writing the
  /// result back only if it differs from the input.
  ///  - not phone-like (email, letters)  -> returned untouched
  ///  - starts with 0   -> "0300 0000000"   (11 digits max)
  ///  - starts with + or 0092 -> "+92 300 0000000"
  ///  - anything else (e.g. bare "3001234567") -> untouched; still valid
  static String formatLocalFull(String input) {
    final t = input.trim();
    if (!looksLikePhone(t)) return input;

    var d = t.replaceAll(RegExp(r'\D'), '');
    final international = t.startsWith('+') || d.startsWith('0092');

    if (international) {
      if (d.startsWith('0092')) d = d.substring(2); // 0092… -> 92…
      if (d.length > 12) d = d.substring(0, 12);
      final b = StringBuffer('+');
      for (var i = 0; i < d.length; i++) {
        if (i == 2 || i == 5) b.write(' ');
        b.write(d[i]);
      }
      return b.toString();
    }

    if (!d.startsWith('0')) return input;
    if (d.length > 11) d = d.substring(0, 11);
    if (d.length <= 4) return d;
    return '${d.substring(0, 4)} ${d.substring(4)}';
  }

  /// A real Pakistani mobile: exactly 10 subscriber digits starting with 3.
  static bool isValid(String input) =>
      RegExp(r'^3[0-9]{9}$').hasMatch(_subscriberDigits(input));

  /// Normalized E.164 (+923001234567) for Supabase Auth, or null if invalid.
  static String? toE164(String input) =>
      isValid(input) ? '+92${_subscriberDigits(input)}' : null;

  /// "0300 1234567" — accepts any format above, including E.164.
  static String toLocalDisplay(String input) {
    final s = _subscriberDigits(input);
    if (s.length != 10) return input;
    return '0${s.substring(0, 3)} ${s.substring(3)}';
  }

  static const errorMessage = 'Enter a valid Pakistani mobile number.';
  static const errorPhoneOrEmail =
      'Please enter a valid phone number or email address.';
}
