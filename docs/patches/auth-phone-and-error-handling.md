# Patch: lib/modules/auth/views/login_page.dart

## 1. Use the no-chip formatter, not the chip-paired one

FIND:

    void _onIdentifierChanged(String v) {
      if (_looksLikeEmail) return; // don't reformat while typing an email
      final formatted = PkPhone.formatAsTyped(v);

REPLACE WITH:

    void _onIdentifierChanged(String v) {
      if (_looksLikeEmail) return; // don't reformat while typing an email
      // This field has no separate "+92" chip, so it uses the
      // leading-zero convention ("0300 0000000") a Pakistani user
      // naturally types — not formatAsTyped, which is for fields paired
      // with a visible chip and would otherwise make the "0" vanish as
      // the very first keystroke.
      final formatted = PkPhone.formatLocalFull(v);

## 2. Fix the hint text

FIND:

    hintText: '3XX XXXXXXX or you@example.com',

REPLACE WITH:

    hintText: '0300 0000000 or you@example.com',

That's the whole fix for this file — `isValid`/`toE164` calls elsewhere
in this file are unchanged, since both already accept the leading-0 form
correctly (they always did; only the live-typing display was wrong).

---

# Patch: lib/modules/auth/views/register_owner_page.dart

## Replace _friendlyError with a much more complete mapping, and log the
## real exception so the next unknown case is actually diagnosable
## instead of silently becoming "Could not create account" again.

FIND (the whole method):

    String _friendlyError(String raw) {
      final lower = raw.toLowerCase();
      if (lower.contains('already registered') || lower.contains('already exists')) {
        return 'An account already exists with this email.';
      }
      if (lower.contains('password should be at least')) {
        return 'Please choose a stronger password (6+ characters).';
      }
      return 'Could not create account. Please check your details.';
    }

REPLACE WITH:

    String _friendlyError(String raw) {
      final lower = raw.toLowerCase();

      if (lower.contains('already registered') || lower.contains('already exists')) {
        return 'This email is already registered. Please sign in or use another email.';
      }
      if (lower.contains('password should be at least') ||
          lower.contains('password should contain') ||
          lower.contains('weak password') ||
          lower.contains('at least 6 characters')) {
        return 'Password must be at least 6 characters.';
      }
      if (lower.contains('invalid email') || lower.contains('unable to validate email')) {
        return 'Please enter a valid email address.';
      }
      if (lower.contains('rate limit') ||
          lower.contains('for security purposes') ||
          lower.contains('too many requests')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      if (lower.contains('socketexception') ||
          lower.contains('failed host lookup') ||
          lower.contains('network') ||
          lower.contains('connection')) {
        return 'Unable to connect. Please check your internet connection and try again.';
      }
      if (lower.contains('permission') || lower.contains('rls') || lower.contains('denied')) {
        return 'Your account could not be created because access to the '
            'database was denied. Please contact support.';
      }

      // Deliberately NOT shown to the user (no raw exception text, no
      // stack traces, no internal details) — but logged so the actual
      // cause is visible in `flutter run`'s console the next time this
      // happens, instead of being silently swallowed into a generic
      // message with no way to diagnose it further.
      debugPrint('SIGNUP_ERROR (unmapped): $raw');
      return 'Could not create account. Please try again in a moment.';
    }

## Why this matters

Every case above that ISN'T matched falls through to the last line,
which used to be the only outcome for anything unrecognized — including
plain network errors, which look identical to "your details are wrong"
from the user's side. The added categories (rate limiting, invalid
email, network, permission-denied) are real GoTrue/Postgres error
patterns this project can hit; expanding the match list turns most of
them into an accurate message instead of the generic one. Whatever is
still NOT matched now gets logged with the `SIGNUP_ERROR` prefix — run
`flutter run`, reproduce the failure, and send me that exact printed
line. That's the one thing I can't determine without your device's
actual console output, and it's the fastest path to a definitive root
cause if this still shows the generic message after the patch.
