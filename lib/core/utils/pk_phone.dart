/// Pakistani mobile number formatting, validation and normalization.
///
/// A Pakistani mobile number is 10 digits after the leading 0 (or +92),
/// starting with 3, e.g. 0300 1234567 / +92 300 1234567 / 03001234567 all
/// refer to the same number. Every Auth call in this app should use the
/// normalized E.164 form ([toE164]) so the same person can't accidentally
/// end up as two different accounts because they typed the number two
/// different ways.
class PkPhone {
  /// Strips everything except digits, then strips a leading country code
  /// (92) or trunk prefix (0), leaving exactly the 10-digit subscriber
  /// number (e.g. "3001234567").
  static String _digitsOnly(String input) {
    var d = input.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0092')) d = d.substring(4);
    if (d.startsWith('92') && d.length > 10) d = d.substring(2);
    if (d.startsWith('0')) d = d.substring(1);
    return d;
  }

  /// Live-formats input as the user types into "3XX XXXXXXX" (10 digits,
  /// space after the 3rd). Use as a TextField's onChanged, feeding the
  /// result back into the controller.
  static String formatAsTyped(String input) {
    final d = _digitsOnly(input).substring(
        0, _digitsOnly(input).length > 10 ? 10 : _digitsOnly(input).length);
    if (d.length <= 3) return d;
    return '${d.substring(0, 3)} ${d.substring(3)}';
  }

  /// True for a real Pakistani mobile prefix (3 followed by 00-49, i.e.
  /// the 0300-0349 through currently-allocated 03XX ranges) and exactly
  /// 10 digits total. Deliberately permissive on the last two digits of
  /// the prefix block since carriers periodically get new blocks
  /// allocated — the structural shape (3 + 9 digits) is what actually
  /// distinguishes a mobile number from a landline or garbage input.
  static bool isValid(String input) {
    final d = _digitsOnly(input);
    return RegExp(r'^3[0-9]{9}$').hasMatch(d);
  }

  /// Normalized E.164 form for Supabase Auth (phone sign-in, OTP, etc.):
  /// +923001234567. Returns null if [input] isn't a valid Pakistani
  /// mobile number — check [isValid] first, or handle the null.
  static String? toE164(String input) {
    if (!isValid(input)) return null;
    return '+92${_digitsOnly(input)}';
  }

  /// Local display form: 0300 1234567. Accepts any of the formats
  /// [_digitsOnly] understands, including an already-E.164 string.
  static String toLocalDisplay(String input) {
    final d = _digitsOnly(input);
    if (d.length != 10) return input;
    return '0${d.substring(0, 3)} ${d.substring(3)}';
  }

  static const errorMessage = 'Enter a valid Pakistani mobile number.';
}
