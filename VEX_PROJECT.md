# VEX Project

- `vex_health/` — the VEX Health Flutter app (Kurdish Sorani UI): Band, heart, sleep, stress, steps, food scan.
- `food_full/` — "خواردن کامل": the complete food section for Flutter. The web food page (700+ foods, circular cut-out photos) hosted via `flutter_inappwebview`, plus Dart glue code. Start with `food_full/خواردن_کامل_README.md`.

Note: the Flutter code has been syntax-checked only (no Flutter compiler was available when it was written); test on a real device.
- `live_app/` — the published live HTML app (https://claude.ai/artifact/CzgAuT3FYHcSpbqUmXHC8q): `index.html` + the `build/*.py` patch scripts that produced it.

## Key decisions (2026-10-22)
- Sign-in by phone or Gmail (Gmail is demo-only; real Google sign-in needs `google_sign_in` + Client ID). Test OTP: 123456.
- Per-account vault (`vexaccounts`, keyed by phone/email) restores Plus, Band and all data on the same phone; a backend is needed for other devices.
- Plus-only: VEX AI, family circle, workout. Band-only: health ring, heart, SpO2, stress/HRV, sleep, skin temperature. Locked areas stay frosted until Plus is bought / Band connected. Free plan: 3 scans per day (`ScanQuota`).
- Flutter details: `vex_health/AUTH_GATE.md`. Colour tool must report 0 problems: `python3 tools/color_fix/apply.py lib --check`.
