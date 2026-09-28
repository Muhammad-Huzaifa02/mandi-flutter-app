# Fixes from your `flutter analyze` / `flutter test` run

## 0. Drop-in files in this zip (overwrite; nothing else to merge)

- `lib/core/utils/pk_phone.dart`  (replaces last turn's version, which had three bugs — see the chat reply)
- `lib/core/utils/pk_cnic.dart`
- `test/pk_phone_test.dart`, `test/pk_cnic_test.dart`  (new)

Then delete the stock template test:

    Remove-Item test\widget_test.dart

## 1. `flutter test` failure — not a bug in the app

`test/widget_test.dart` is the untouched "Counter increments smoke test"
that `flutter create` generates. It pumps the app and looks for a "0"
counter. Mandi isn't a counter app, and `AppRoot` needs
`Supabase.initialize()` (done in `main()`, which tests don't run) before
`AuthProvider` can be built — hence "You must initialize the supabase
instance". It was failing before any of our changes. The two new test
files are pure Dart (no Supabase, no widgets) and cover the phone/CNIC
rules from your TEST 1–5.

## 2. Sign In validator message (login_page.dart)

FIND:

    return PkPhone.isValid(v) ? null : PkPhone.errorMessage;

REPLACE WITH:

    return PkPhone.isValid(v) ? null : PkPhone.errorPhoneOrEmail;

And the email branch — FIND:

    return v.contains('.') ? null : 'Enter a valid email';

REPLACE WITH:

    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
        ? null
        : PkPhone.errorPhoneOrEmail;

(No other change to login_page.dart is needed: it already calls
`PkPhone.formatLocalFull`, which is now safe for emails.)

## 3. Mechanical analyzer items — let Flutter fix them

    dart fix --dry-run
    dart fix --apply

This handles the `prefer_const_constructors` items (welcome_page.dart:37,
employee_detail_page.dart:243, dashboard_page.dart:40) and the unused
import. Then re-run `flutter analyze` for what's left.

## 4. Deprecations (do by hand if `dart fix` skips them)

| Where | Change |
|---|---|
| add_employee_page.dart:170, employee_detail_page.dart:185 | `DropdownButtonFormField(value: _roleId, …)` -> `initialValue: _roleId` |
| employee_list_page.dart:105, :121 | `.withOpacity(0.12)` -> `.withValues(alpha: 0.12)` |
| shop_setup_wizard.dart:10 | delete `import 'package:mandi/providers/auth_provider.dart';` (unused — the wizard now reads the session from Supabase directly) |
| main.dart:19 | optional: `anonKey:` -> `publishableKey:` (same value; info-level only, `anonKey` still works today) |

(`value:` -> `initialValue:` is the reverse of what I did earlier for old
SDKs; your Flutter is newer, so the new name is right.)

## 5. `use_build_context_synchronously` — these are real, fix them

Using `context` after an `await` can crash if the screen was closed
meanwhile. Pattern: read what you need from context **before** the first
await.

**shop_setup_wizard.dart (lines ~218, ~224)** — at the very top of `_finish()`:

    final shopCtx = context.read<ShopContextProvider>();

then replace both later uses:

    context.read<ShopContextProvider>().adoptNewShop(...)      ->  shopCtx.adoptNewShop(...)
    await context.read<ShopContextProvider>().loadForUser(uid) ->  await shopCtx.loadForUser(uid)

**dashboard_page.dart (line ~24)** — the logout handler:

    onPressed: () async {
      final auth = context.read<AuthProvider>();          // before any await
      final shopCtx = context.read<ShopContextProvider>(); // before any await
      final ok = await showDialog<bool>(...);
      if (ok != true) return;
      await auth.signOut();
      shopCtx.clear();
    }

## 6. Heads-up: phone login only works for accounts that HAVE that phone in Supabase Auth

`signInWithPhone` looks up a Supabase Auth user by phone. An owner who
registered with email (as the current Create Account screen does) has no
phone on their Auth user, so typing their phone on Sign In will say
"Incorrect phone/email or password" even though the number is stored on
their shop membership. That's a design gap, not a formatting bug. Options
when you're ready: (a) register owners with phone as an Auth identity
(needs an SMS provider configured in Supabase), or (b) a small RPC that
maps phone -> email for login (simple, but lets anyone test whether a
number is registered — a trade-off to decide on deliberately).
