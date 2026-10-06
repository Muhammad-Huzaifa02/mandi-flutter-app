# Mandi — Design System

## Brand & Visual Language

Emerald green + gold, Poppins typeface, mobile-first, 3D Liquid Glassmorphism card-based layout inspired by iOS floating design language.

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

## 3D Liquid Glassmorphism Tokens (`GlassCard`, `GlassContainer`)

- **Frosted Backdrop Filter**: `BackdropFilter(sigmaX: 16, sigmaY: 16)`.
- **Translucent Glass Surface**: `Colors.white.withValues(alpha: 0.85)` (Light) / `Colors.white.withValues(alpha: 0.08)` (Dark).
- **3D Ambient Floating Shadows**: Layered ambient box shadows (`BoxShadow` with spread and blur).
- **Gloss Borders**: `Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.2)`.

## Spacing / radius / type (`MSpacing`, `MRadius`, `MText`)

- `MSpacing.md = 16.0` — standard gap scale (`xs`/`sm`/`md`/`lg`/`xl`).
- `MRadius.md = 14px`, `MRadius.lg = 20px`, `MRadius.full = 999px` (pills, chips, badges).
- `MText.displayMd` / `titleLg` / `bodyMd` / `labelMd` / `labelSm` — named text styles.

## Screen patterns

- **Floating Glass Dashboard**: Floating frosted glass cards (`GlassCard`) for shop welcome banners and permission-gated management tiles.
- **Floating Input Fields**: Rounded pill text fields (`BorderRadius.circular(16)`) with subtle floating borders.
- **Confirm-before-destructive**: `AlertDialog` for access changes (deactivate, reset password).
- **List → Add → Detail**: Separate modular screens per domain.
