; - - -
;; Default settings
; Tracked in git. Don't edit it for your machine: create `config.ahk` next
; to it (not tracked) and assign only what you want to change. It is
; included after this file, so its values win.

;; - General
DEBUG := false ; Diagnostic tooltips
DELAY := 50 ; ms between sends
HINTS := true ; Window with the keys of a "combo, then key" menu

;; - Modules
; Turns the feature modules in lib\ on (true) or off (false). An off
; module's keys and hotstrings pass through to the active app. To change
; one, put e.g. MODULES["mouse"] := false in config.ahk.
MODULES := Map(
    "emoji", true,      ; Alt+Shift+E menu
    "datetime", true,   ; Alt+Shift+T menu
    "markup", true,     ; link and code menus
    "hotkeys", true,    ; global remaps (taskbar volume, NumpadDot, ...)
    "apps", true,       ; app remaps (incl. foobar2000, VirtuaWin)
    "window", true,     ; window placement, always on top
    "diag", true,       ; window, monitor and locale info
    "mouse", true,      ; mouse precision mode
    "hotstrings", false ; Russian abbreviations
)
DEFAULT_MODULES := MODULES.Clone() ; Fallbacks, kept from config.ahk changes

;; - Menu hotkeys
; The combos that open the "combo, then key" menus: modifiers (Ctrl, Alt,
; Shift, Win) and a key, joined with "+". "" turns a menu off. To change
; one, put e.g. MENU_KEYS["emoji"] := "Ctrl+Alt+E" in config.ahk. A bad or
; duplicate combo is reported at startup and the default is used.
MENU_KEYS := Map(
    "emoji", "Alt+Shift+E",
    "datetime", "Alt+Shift+T",
    "link", "Alt+Shift+L",
    "code", "Alt+``",
    "codeblock", "Ctrl+Shift+``",
    "info", "Ctrl+Alt+I"
)
DEFAULT_MENU_KEYS := MENU_KEYS.Clone() ; Fallbacks, kept from config.ahk changes

;; - Issue trackers
; Alt+Shift+L, t: a URL "https://<host><path>KEY-123..." becomes
; [KEY-123](url). "host" and "path" are regular expressions (escape the
; dots); add one Map per tracker.
TRACKERS := Map(
    "jira", Map("host", "jira\.example\.com", "path", "/browse/"),
    "youtrack", Map("host", "youtrack\.example\.com", "path", "/issue/")
)
