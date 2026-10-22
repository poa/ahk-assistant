# AGENTS.md

Guidance for coding agents working in this repository.

## Project

AutoHotkey v2 toolkit for Windows. User docs and the full hotkey
reference are in `README.md`.

`Assistant.ahk` is the one resident script: it holds directives,
settings and globals, and includes the feature modules in `lib/`. A
function used by more than one module lives in `lib/tools.ahk`.

## Plans and decisions (`.ai/`)

AI-assisted work is kept in git, so it can continue on another machine:

- **`.ai/plans/<topic>.md`:** one file per plan.
  - When a plan is approved, copy it here. Tool-specific plan files,
    such as `~/.claude/plans/`, stay on one machine.
  - Every step commit ticks the step in the plan's Status section and
    updates "Next".
- **`.ai/decisions.md`:** a log of the user's decisions, oldest first.
  - Each entry is a dated heading with Decision, Why and Rejected
    lines.
  - Append an entry when the user makes a decision.
  - Never rewrite old entries; add a new one that names the decision it
    supersedes.
- **To resume:** read the active plan's Status, then
  `git log --oneline` on its branch.

## Runtime

- **AutoHotkey v2** (2.0+) for every script. Default install:
  `C:\Program Files\AutoHotkey\v2\`.
- Every entry script starts with `#Requires AutoHotkey v2.0`, so the
  launcher picks the right interpreter. Don't use v1 syntax.

## Checking changes

No build or linter. Run these from the repo root, in WSL or Git Bash on
Windows. The commands use WSL paths (`/mnt/c/...`); for Git Bash, see
the note below.

Syntax check: loads `Assistant.ahk` and everything it includes without
running it. Exit 0 means OK; otherwise exit 2 with
`file (line) : ==> message` on stdout. It must also print no
`Warning:` lines:

```sh
"/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe" /ErrorStdOut /validate Assistant.ahk
```

A Claude Code hook runs this check for you after every Edit, Write or
Bash tool call: `.claude/hooks/ahk-validate.sh`, registered in
`.claude/settings.json`.
- **What it checks:** when `Assistant.ahk`, `lib/` or `config*.ahk`
  changed, it validates `Assistant.ahk`. Other v2 scripts in the root
  (`#Requires AutoHotkey v2`) are validated on their own.
- **What you get:** errors and warnings come back as hook feedback.
  Each broken state is reported once per session.
- **Limits:** it never runs the script, so the smoke run below stays
  manual. If AutoHotkey v2 isn't in the default place, set
  `AHK_V2_EXE`. A new folder with v2 entry scripts must be added to
  the hook's target list.
- **Git Bash:** it rewrites `/`-arguments such as `/validate` into
  paths, and AutoHotkey then exits 2 with no message. The hook turns
  this off itself; for the commands here, prefix `MSYS_NO_PATHCONV=1`
  and use `/c/...` instead of `/mnt/c/...`.

`/validate` only finds load-time problems. Startup code (the top-level
code of each module) can still fail at run time, and a runtime error
opens a dialog. This smoke run executes the startup code once, then
exits; it must print nothing and exit 0 (`timeout` ends it if a dialog
blocks):

```sh
{ sed 's/^#SingleInstance.*/#SingleInstance Off/' Assistant.ahk; echo ExitApp; } \
  | timeout 20 "/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe" /ErrorStdOut '*'
```

Unit checks for the layout-independent key names (`KeyNameUS()`, run in
the US and the Russian layout), the link builder (`MakeLink()`), the
menu hint parser and the menu combos: `tests/menus.ahk`. It prints
failures and a summary, and exits with the number of failures:

```sh
"/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe" /ErrorStdOut tests/menus.ahk
```

Hotkeys against the README (the tables must match the code):
`tests/readme-coverage.ahk` lists every hotkey of `Assistant.ahk` and
`lib/`, and the default menu combos (`MENU_KEYS`), as ok or MISSING,
then the README notations with no such hotkey, for a manual check. The
exit code is the number of missing hotkeys. Run it by hand after
changing a hotkey; no hook runs it. A hotkey counts as documented if the
README mentions it anywhere, not only in a table.

```sh
"/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe" /ErrorStdOut tests/readme-coverage.ahk
```

The menus script can't press keys, so `GetOneKey()` and the menus stay
manual. Add a check there when you change `KeyNameUS()`, `MakeLink()`,
`ParseHint()` or `ComboToHotkey()`.

Module switches (`MODULES`): `tests/modules.ahk` reads each `lib/`
module and fails if a hotkey or hotstring isn't under a `#HotIf` with
its module's `ModuleOn("…")`, if a file doesn't end with a bare `#HotIf`,
if a `MenuHotkey()` call names another module, or if `MODULES` and the
files disagree. A new `lib/` file must be added to its `fileModules`
map. It exits with the number of failures:

```sh
"/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe" /ErrorStdOut tests/modules.ahk
```

Window sizes: `tests/window.ahk` checks `RegionRect()` (halves,
quarters and the `WINDOW_STEPS` fractions, on even and odd work areas),
the Ctrl+Win+arrows step cycle (`NextWindowStep()`) and the
`WINDOW_STEPS` check. It moves no window and exits with the number of
failures. Add a check there when you change the window geometry:

```sh
"/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe" /ErrorStdOut tests/window.ahk
```

To check how a built-in behaves, pipe a print-only probe script to the
interpreter instead of writing files: `… /ErrorStdOut '*'` reads the
script from stdin (quote the `*`), and `FileAppend "…", "*"` prints. A
stdin script's `A_ScriptDir` is the current directory. The Windows
interpreters can't read `/tmp`; use `\\wsl.localhost\<distro>\tmp\…`.

Behaviour can only be tested by hand on Windows: reload with Ctrl+Alt+R
and press the hotkey. If you couldn't test by hand, say so.

## Layout

- **`Assistant.ahk`:** directives, includes. Put new code in a `lib/`
  module, not here.
- **`config.default.ahk`, `config.ahk`:** settings (see Conventions);
  `config.ahk` is gitignored.
- **`lib/`:** `tools.ahk` (shared helpers; put new reusable functions
  here) and `script.ahk` (reload, hide a tooltip) are always on. The
  modules, switched by `MODULES`: `snippets-{emoji,datetime,markup}.ahk`,
  `hotkeys.ahk`, `apps.ahk`, `window.ahk`, `diag.ahk`, `mouse.ahk`, and
  `hotstrings.ahk` (Russian abbreviations, off by default; included
  after the `#Hotstring EndChars` directive it relies on).
- **`tests/`:** `menus.ahk`, `modules.ahk`, `window.ahk`, `readme-coverage.ahk` (see
  "Checking changes").
- **`docs/`:** screenshots for the README.
- **`.claude/`:** Claude Code project settings and the validate hook
  (see "Checking changes").
- **AI artefacts:** `.ai/plans/`, `.ai/decisions.md` (see above).

## Conventions

- 4-space indent. Sections start with `; - - -` + `;; Heading`; items are
  `;; - Item`; doc comments are `/** … */`. AHK++ (VS Code) shows `;;`
  lines in the outline.
- "Press combo, then a key" menus: `key := GetOneKey(hint)` then
  `switch KeyNameUS(key)`. `GetOneKey()` returns a scan code (`scNNN`)
  and `KeyNameUS()` turns it into the US-layout key name, so the menu
  doesn't depend on the keyboard layout. Don't use `GetKeyName()` for
  this: it names letter and punctuation keys by the active layout (the
  S key is "ы" in the Russian one). Shifted keys: `GetOneKey(hint,
  &shift)`, then `(shift ? "+" : "") KeyNameUS(key)` (`"+v"`).
  The `hint` is shown in a window (`ShowHint()`; format in
  `ParseHint()`): an optional first line `==Title==`, then a row per
  line; `|` separates cells in a row, and a cell is `key: label`. `|`
  and `:` are never key names (they are `+\` and `+;`), so `;` can be a
  key. Join alternative keys with a comma (`6,w: ⚠️`). Write Shift as
  `+`, as in the `switch` cases; the window shows it as `⇧` (`+v` ->
  `⇧v`). A cell without `key:` throws, and `tests/menus.ahk` parses
  every `HintText` block in `lib/`. Write the hint as a `HintText`
  continuation section laid out like the window, then call
  `GetOneKey(HintText)`:

  ```ahk
  HintText := "
  (
  ==Code==
  ``: selection
  v: clipboard
  )"
  ```

  A menu whose labels are computed builds `HintText` in code from the
  same values it sends (Alt+Shift+T, in `lib/snippets-datetime.ahk`);
  the tests don't see such a hint.
- **Menu combos are configurable.** A menu isn't a `x::` hotkey: its
  module calls `MenuHotkey(name, module, callback)` at its top, and the
  combo comes from `MENU_KEYS` in `config.default.ahk` (readable
  notation, `"Alt+Shift+E"`, turned into a hotkey name by
  `ComboToHotkey()`). A bad or duplicate combo falls back to the default
  and is reported in one message after startup (`ReportConfig()`). A
  callback gets the hotkey name; to pass the combo on, use
  `PassMenuCombo(name)`, not a fixed combo. A new menu needs an entry in
  `MENU_KEYS`. Other hotkeys, including app-scoped ones, stay fixed
  `x::` definitions.
- **Modules can be switched off** (`MODULES`, checked by `ModuleOn()`).
  All modules are always included (`#Include` can't depend on a
  setting); a switched-off module's keys just don't fire. So every
  hotkey and hotstring of a module sits under
  `#HotIf ModuleOn("<module>")`; an app-scoped one combines both:
  `#HotIf ModuleOn("apps") && (IsActiveApp("outlook"))`. A menu passes
  its module to `MenuHotkey(name, module, callback)`, which registers
  the combo under the same condition; to pass the combo on, use
  `PassMenuCombo(thisHotkey)`. A new module needs an entry in `MODULES`
  and in `fileModules` (`tests/modules.ahk`). Keys that must always work
  go in `lib/script.ahk`.
- Settings and globals live in `config.default.ahk` (tracked: `DEBUG`,
  `DELAY`, `HINTS`, `MENU_KEYS`, `MODULES`, `TRACKERS`, `WINDOW_STEPS`). `config.ahk` is the
  user's optional, untracked override, included after it with
  `#Include *i`. Never put machine- or company-specific values (hosts,
  titles) in tracked files: the default file holds generic examples and
  the repository is public.
- **Window detection** lives only in `lib/tools.ahk`. A window has one
  **app** (the program, matched by class or exe: `GetActiveApp()`,
  `IsActiveApp(alias)`) and at most one **service** (the site or
  document, matched by title: `GetActiveService()`,
  `IsActiveService(alias)`). Confluence in Firefox is app `firefox` and
  service `confluence`. Unknown windows are `general`; an unknown alias
  throws.
  - To support a new app or service, add a rule to `AppRules()` or
    `ServiceRules()`. Don't match window titles, classes or exes
    anywhere else.
  - Service rules match the page title: `PageTitle()` cuts the
    browser's name off the window title (`X - Jira - Brave` ->
    `X - Jira`), so a rule needs no browser suffixes. A new browser
    goes into `PageTitle()`.
  - Markup snippets use `GetMarkupTarget()` (built on the service).
- When adding, changing or removing a hotkey, update the tables in
  `README.md`.

## Code rules

- `#Warn All, StdOut` is on. All v2 warnings are load-time, so the
  `/validate` check above shows them.
- **Top-level code in a module runs at startup**, in include order.
  A module that needs init does it at its top (as `lib/mouse.ahk`
  does). Functions are defined before anything runs, but its startup
  code must not read globals that a later module sets.
- A function or hotkey that **assigns** a global must declare it
  (`global BreakLoop`); otherwise v2 silently creates a local. Reading a
  global needs no declaration.
- Scope app-specific keys with `#HotIf IsActiveApp("…")` or
  `#HotIf IsActiveService("…")`. Every file that opens a `#HotIf` block
  ends with a bare `#HotIf`.
- Send literal text with `SendText`. Never pass markup such as `{code}`
  to `Send`, which reads braces as key names.
- Clipboard work goes through `lib/tools.ahk`: `CopySelection(&saved,
  &clipText)`, then `PasteText(text)`, then `RestoreClipboard(saved)`.
  This keeps non-text clipboard contents. A hotkey that does clipboard
  work runs through `GuardClipboard(Func)`, so a busy clipboard shows a
  tooltip instead of an error dialog.
- `switch` is case-sensitive (in v1 it was not).
- **Runtime errors open a dialog**, and `/validate` only catches
  load-time problems. Where v1 failed silently, v2 often throws: wrap
  calls on windows that may vanish in `try`, and give values passed to
  `Format("{:d}")` a numeric default (v2 throws on `""`). In stdin
  probes, catch and print errors, or the dialog blocks.
- Win functions without a WinTitle use the "last found window". Hotkey
  threads start without one, so they throw.
- Names are case-insensitive and share one namespace with functions
  and classes: a variable `buffer` clashes with the `Buffer` class.
- `ControlGetPos` returns client-area coordinates.
- **Place windows with `MoveWindowFrame(hwnd, rect)`** (`lib/window.ahk`),
  not a bare `WinMove`. Windows 10/11 windows have invisible resize
  borders (7 px at 100%, left, right and bottom), so `WinMove` with a
  visible size leaves the window too big and overlapping its neighbour.
  `MoveWindowFrame()` adds the window's real borders (from DWM).
- **Measure and move a window in its own DPI awareness:** wrap the work
  in `InWindowDpi(hwnd, fn)` (`lib/window.ahk`), as `WindowMove()` and
  `WindowStep()` do. AutoHotkey is only system-DPI aware, so with
  monitors of different scaling Windows reports scaled coordinates (a
  1920 px monitor at 100% next to a 150% one is 2880 px wide), and a
  modern app's window lands wrong. A move in per-monitor mode for every
  window doesn't work either: Windows rescales an older app's window
  whose border reaches into a monitor of other scaling. DWM's frame
  bounds are always real pixels; `FrameBorders()` scales them to the
  caller's coordinates.
- v2 reads scripts as UTF-8, with or without a BOM.
- v2 doesn't auto-include function libraries: a function in
  `lib\Foo.ahk` needs an `#Include`, even when the file is named after
  it.

## Git

- `master` is the main line. Base branches and pull requests on `master`.
- From WSL on a Windows checkout, git may report "dubious ownership".
  Use `git -c safe.directory=<repo path> …`.
- **The repository is public: no personal or sensitive data, ever.**
  Before every commit (and before amending or pushing), check what is
  staged and the commit identity. Commit only when every check is clean;
  otherwise remove the data and tell the user. Never put any of this in
  tracked files, commit messages or file names:
  - personal names, emails, user names, and paths under `C:\Users\…`;
  - company, customer or project names, internal hosts, URLs and IPs;
  - passwords, tokens, API keys, credentials, cookies;
  - machine-specific values (they belong in the untracked `config.ahk`,
    which is never committed);
  - screenshots or other binaries showing any of the above: look at
    every added or changed image.

  The checks, from the repo root:

  ```sh
  # Generic patterns in the staged files: review every match
  git grep --cached -n -I -i -E '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}|https?://|\b([0-9]{1,3}\.){3}[0-9]{1,3}\b|[a-z]:\\users|password|passwd|secret|token|api[_-]?key|credential' -- . ':!LICENSE'
  # The maintainer's own private terms: one per line in .private-terms
  # (gitignored, never committed); there must be no match at all
  [ -f .private-terms ] && git grep --cached -n -I -i -F -f .private-terms
  # Staged files: config.ahk and .private-terms must not appear
  git diff --cached --name-only
  # Identity: only the GitHub no-reply address may appear
  git config user.email; git log --format='%an <%ae> / %cn <%ce>' | sort -u
  ```

  Expected matches of the first check: this rule itself, the public
  links in `README.md`, the RFC links in `lib/snippets-markup.ahk`, the
  `https://<host>` placeholder in `config.default.ahk`, and the example
  URLs in `tests/menus.ahk` (`http://x`, `*.example.com/org`,
  `github.com`). Anything else needs a look. The commit message is
  checked the same way before committing.
- Commit messages: a short imperative subject, a blank line, then a body
  saying what changed and why. No AI attribution or `Co-Authored-By`
  lines.
- Commit only when asked. An approved plan in `.ai/plans/` can grant
  standing approval for one commit per step.
