# Changelog

## v1.0.1 — 2026-10-25

- The early ability grant could remain waiting for gameplay when persistent event flags were set.
- Fix event-bitfield detection: persistent high flags such as `0x18` no longer count as an active cutscene by themselves. Low event blockers and existing gameplay guards remain enforced.
- The same faulty check was corrected. Lua gameplay-gate tests cover the captured flag value and existing guards; a fresh live ability grant has not been retested for this fix.
- Close KH1 normally before updating; replace the previous copy, rebuild in OpenKH, and restart. Native helpers cannot be replaced with F1 reload.

## Distribution update — 2026-10-07

- Add a ready-to-import OpenKH ZIP, SHA256 checksum, and standalone package builder.
- Document downloaded ZIP import as the third installation method.
- Gameplay script and version 1.0.0 remain unchanged.

## 1.0.0

Initial standalone community release, extracted from the gameplay-tested combined mod.
