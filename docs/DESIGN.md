# Mandi — Design System

## Brand

Emerald green + gold, Poppins typeface, mobile-first, card-based layout.
Chosen to read as a modern, professional Pakistani business app —
not generic Material defaults, not a copy of Saith Commission Shop's own
branding (each shop can eventually customize its own logo/colors on top
of this default).

## Color tokens (`MColors`, `lib/core/theme/app_theme.dart`)

| Token | Hex | Use |
|---|---|---|
| `primary` | `#0F6B3C` | Primary brand emerald |
| `primaryDark` | `#0A4A29` | Gradients, dark surfaces (splash/welcome background) |
| `gold` | `#D4A62A` | Secondary brand accent, primary CTA on dark backgrounds |
| `goldLight` | `#E8C767` | Gold gradient highlight |
| `danger` | `#C0392B` | Destructive actions, error states |
| `warning` | `#D4A62A` | Pending/invited states (shares gold) |
| `success` | `#2E8B57` | Active status, confirmations |

The app icon and in-app logo (`assets/icons/app_icon.png`,
`assets/images/logo.png`) use exactly `primaryDark`/`gold` as their
background/glyph pair — an original stylized wheat-stalk mark, not
copied from any existing brand.

## Spacing / radius / type (`MSpacing`, `MRadius`, `MText`)

- `MSpacing.md = 16.0` — the standard gap; also has `xs`/`sm`/`lg`/`xl`
  following the same scale.
- `MRadius.md` = 14px corner radius (cards, inputs); `MRadius.full` =
  999px (pills, chips, badges).
- `MText.displayMd` / `titleLg` / `bodyMd` / `labelMd` / `labelSm` —
  named text styles; don't hardcode a `TextStyle` when one of these
  already fits.

## Screen patterns already established

- **Dark gradient screens** (Splash, Welcome): `primaryDark` →
  `primary` gradient background, white/gold text, used only for the
  pre-auth entry screens — every screen after login is light-surfaced.
- **Forms**: labeled `TextFormField`s, `MSpacing.md` between fields,
  inline error text in `danger` directly under the field it belongs to
  (not a toast/snackbar) for validation errors specifically — snackbars
  are reserved for action results ("Saved.", server errors).
- **Status badges**: pill-shaped, tinted background at low opacity +
  full-strength text/icon in the matching color (`active` → success
  tint, `inactive` → danger tint, `invited` → warning tint).
- **Confirm-before-destructive**: an `AlertDialog` for anything that
  changes access (deactivate, reset password) — never a bare button
  that acts immediately.
- **List → Add → Detail** as three separate screens per module (see the
  Staff module), not a single screen with modes.

## Interactive prototype's visual language (HTML mockups, not yet in Flutter)

The standalone HTML prototypes explored a more elevated "3D" language —
layered shadows, soft gradients on buttons, staggered card entrance
animation, glass-effect app bars — that the real Flutter app hasn't
adopted yet. If asked to bring that into the real app, the tokens to
add would be: a `--sh-1/2/3` layered-shadow scale (ambient + contact
shadow, not a single flat `BoxShadow`), a `MColors.emeraldPale`
background tint for info banners (used in the prototype's "assigned
automatically to this shop" callouts), and a shared staggered-entrance
animation helper for list screens. None of this exists in
`app_theme.dart` yet — it would be new tokens, not a rename of existing
ones.

## Iconography

Material Icons only so far (`Icons.storefront`, `Icons.lock_reset`,
`Icons.block`, etc.) — no custom icon set. The HTML prototypes used
emoji as placeholder icons (🌾 👥 🧾); treat those as stand-ins for
proper icons/illustrations if the real app ever needs that module's
screen, not as the intended final look.
