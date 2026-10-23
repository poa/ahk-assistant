# Decisions

Decisions made by the user during AI-assisted work, oldest first.
Entries are never rewritten. A changed decision gets a new entry that
names the one it supersedes.

## 2026-10-22: Configurable mouse precision hotkeys

- **Decision:** the precision-mode combos come from a new `MOUSE_KEYS`
  map, parsed, checked for clashes and reported like `MENU_KEYS`. The
  defaults: hold the back side button (`XButton1`) for a slow mouse,
  Ctrl+Alt+M to toggle it (were Ctrl+Alt+LShift held and RCtrl+RAlt).
  The slow speed is a setting too, `MOUSE_SLOW_SPEED` (default 1).
- **Why:** the old combos were awkward to press and could only be
  changed in the code. The side button then no longer works as Back.
- **Rejected:** Ctrl+Alt+N (hold) with Ctrl+Alt+M; toggle only; keeping
  the old combos; entries in `MENU_KEYS` (they aren't menus); a fixed
  slow speed.

## 2026-10-23: Alt+Shift+T: ISO on i, a short stamp on s

- **Decision:** in the Alt+Shift+T menu, `i` types the ISO timestamp
  (`2026-10-14T18:05:09`, was on `s`), and `s` types a short stamp to
  the minute (`2026-10-14-1805`).
- **Why:** user preference; I for ISO, S for stamp.
- **Rejected:** keeping ISO on `s`.
