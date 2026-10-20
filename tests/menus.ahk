#Requires AutoHotkey v2.0
#Warn All, StdOut
; Checks the layout-independent key names, the link builder, the tracker
; lookup, the hint parser (and every menu's HintText) and the clipboard guard. Run from anywhere; prints failures and a summary, exits with the
; number of failures (0 = OK). It registers the hotkeys of the included
; modules for a moment, then exits. Not covered: GetOneKey() (needs a real
; key press) and the menus themselves.
;   AutoHotkey64.exe /ErrorStdOut tests\menus.ahk

DEBUG := false
DELAY := 50
HINTS := false
TRACKERS := Map(
    "jira", Map("host", "jira\.example\.com", "path", "/browse/"),
    "other", Map("host", "tracker\.example\.org", "path", "/(issue|task)/")
)
; The menus of snippets-markup.ahk, and t1…t5 for the MenuHotkey() checks
DEFAULT_MENU_KEYS := Map("link", "Alt+Shift+L", "code", "Alt+``", "codeblock", "Ctrl+Shift+``"
    , "t1", "Ctrl+Alt+Shift+F11", "t2", "Ctrl+Alt+Shift+F12", "t3", "Ctrl+Alt+Shift+F10"
    , "t4", "Ctrl+Alt+Shift+F9", "t5", "Ctrl+Alt+Shift+F11")
MENU_KEYS := DEFAULT_MENU_KEYS.Clone()
; The modules of the included files, and "test" for the menu checks
DEFAULT_MODULES := Map("markup", true, "test", true)
MODULES := DEFAULT_MODULES.Clone()
Critical ; Keeps the ReportConfig() timer from opening a message box mid-run
#Include %A_ScriptDir%\..\lib\tools.ahk
#Include %A_ScriptDir%\..\lib\snippets-markup.ahk

checks := 0
failures := 0

Check(name, got, want) {
    global checks, failures
    checks++
    if (got != want) {
        failures++
        FileAppend "FAIL " name ": got [" got "], want [" want "]`n", "*"
    }
}

/** KeyNameUS() must name the main keys the same in every layout
*/
CheckKeyNames(label) {
    ; Scan code row -> keys of the US layout, left to right
    rows := Map(0x02, "1234567890-=", 0x10, "qwertyuiop[]"
        , 0x1E, "asdfghjkl;'", 0x29, "``", 0x2B, "\", 0x2C, "zxcvbnm,./")
    for first, chars in rows {
        loop parse chars {
            key := Format("sc{:03X}", first + A_Index - 1)
            Check(label " " key, KeyNameUS(key), A_LoopField)
        }
    }
    ; Keys outside the main rows are named by GetKeyName(), the same in every layout
    Check(label " sc001", KeyNameUS("sc001"), "Escape")
    Check(label " sc039", KeyNameUS("sc039"), "Space")
    Check(label " sc037", KeyNameUS("sc037"), "NumpadMult")
    Check(label " sc04A", KeyNameUS("sc04A"), "NumpadSub")
    Check(label " sc04E", KeyNameUS("sc04E"), "NumpadAdd")
}

; The US layout, then the Russian one for this thread
layouts := Map("en", "00000409", "ru", "00000419")
for label, id in layouts {
    hkl := DllCall("LoadKeyboardLayout", "Str", id, "UInt", 0, "Ptr")
    DllCall("ActivateKeyboardLayout", "Ptr", hkl, "UInt", 0)
    if (DllCall("GetKeyboardLayout", "UInt", 0, "Ptr") != hkl) {
        FileAppend "SKIP layout " label ": could not activate it`n", "*"
        continue
    }
    CheckKeyNames(label)
}

Check("link markdown", MakeLink("T", "http://x", "markdown"), "[T](http://x)")
Check("link jira", MakeLink("T", "http://x", "jira"), "[T|http://x]")
Check("link confluence", MakeLink("T", "http://x", "confluence"), "[T](http://x)")
Check("link empty title markdown", MakeLink("", "http://x", "markdown"), "[](http://x)")
Check("link empty title jira", MakeLink("", "http://x", "jira"), "[|http://x]")

; Jira and Confluence windows are found by their keyword only
rules := ServiceRules()
Check("service jira", MatchWinRules(rules, "[AB-1] Fix it - Jira", "", ""), "jira")
Check("service jira company title", MatchWinRules(rules, "[AB-1] Fix it - Example Corp JIRA", "", ""), "jira")
Check("service jira keyword in the middle", MatchWinRules(rules, "Jira notes - Docs", "", ""), "general")
Check("service confluence", MatchWinRules(rules, "Page - Confluence", "", ""), "confluence")
Check("service general", MatchWinRules(rules, "Notepad", "", ""), "general")
apps := AppRules()
Check("app mattermost", MatchWinRules(apps, "Town Square - Mattermost", "Chrome_WidgetWin_1", "Mattermost.exe"), "mattermost")
Check("app other electron app", MatchWinRules(apps, "Slack", "Chrome_WidgetWin_1", "slack.exe"), "general")

; TrackerIssueId() finds the issue key for each configured tracker
Check("issue id jira", TrackerIssueId("https://jira.example.com/browse/AB-12?x=1"), "AB-12")
Check("issue id other", TrackerIssueId("http://tracker.example.org/task/Z9-3"), "Z9-3")
Check("issue id wrong path", TrackerIssueId("https://jira.example.com/projects/AB-12"), "")
Check("issue id unknown host", TrackerIssueId("https://github.com/browse/AB-12"), "")

; ParseHint(): "==Title==", a row per line, "|" separates cells, a cell is "key: label"
CellsText(row) {
    text := ""
    for cell in row
        text .= (text = "" ? "" : " | ") cell[1] "=" cell[2]
    return text
}
HintError(hint) {
    try {
        ParseHint(hint)
        return "no error"
    } catch ValueError as err
        return err.Extra
}
hint := ParseHint("==Title only==")
Check("hint title only", hint.title, "Title only")
Check("hint title only rows", hint.rows.Length, 0)
hint := ParseHint("`n  == Date and time ==`n  a: date time`n  d:date  |  `n")
Check("hint title", hint.title, "Date and time")
Check("hint rows", hint.rows.Length, 2)
Check("hint label with spaces", CellsText(hint.rows[1]), "a=date time")
Check("hint spaces trimmed", CellsText(hint.rows[2]), "d=date")
hint := ParseHint("a: one`nb: two")
Check("hint no title", hint.title, "")
Check("hint no title rows", hint.rows.Length, 2)
hint := ParseHint("==Emoji==`n1: ❗ |  +1: ‼️| 2: ✔️ OK`n6,w: ⚠️ |  7,+/: ❓ |  8: *️⃣`n``: selection`nk:`n+: plus | +=: ➕`nt: time 12:30 | x: a;b")
Check("hint row of cells", CellsText(hint.rows[1]), "1=❗ | ⇧1=‼️ | 2=✔️ OK")
Check("hint alternative keys", CellsText(hint.rows[2]), "6,w=⚠️ | 7,⇧/=❓ | 8=*️⃣")
Check("hint backtick key", CellsText(hint.rows[3]), "``=selection")
Check("hint key without label", CellsText(hint.rows[4]), "k=")
Check("hint plus key and shifted plus", CellsText(hint.rows[5]), "+=plus | ⇧==➕")
Check("hint colon and semicolon in labels", CellsText(hint.rows[6]), "t=time 12:30 | x=a;b")
hint := ParseHint(";: semicolon | +;: colon | \: backslash | +\: pipe")
Check("hint punctuation keys", CellsText(hint.rows[1]), ";=semicolon | ⇧;=colon | \=backslash | ⇧\=pipe")
Check("hint error no colon", HintError("==T==`na selection"), "a selection")
Check("hint error no key", HintError(": label"), ": label")
Check("hint error late title", HintError("a: x`n==T=="), "==T==")

/** Every HintText block in lib/ parses and has a title and keys
*/
CheckLibHints() {
    Loop Files A_ScriptDir "\..\lib\*.ahk" {
        src := FileRead(A_LoopFileFullPath, "UTF-8")
        pos := 1
        while (pos := RegExMatch(src, "s)HintText := `"\R\s*\(\R(.*?)\R\s*\)`"", &m, pos)) {
            name := A_LoopFileName " block " A_Index
            block := StrReplace(m[1], "````", "``")
            try {
                parsed := ParseHint(block)
                Check(name " has a title", parsed.title != "", true)
                Check(name " has keys", parsed.rows.Length > 0, true)
            } catch ValueError as err
                Check(name " parses", "bad cell [" err.Extra "]", "ok")
            pos += m.Len
        }
    }
}
CheckLibHints()

; ComboToHotkey(): readable combo -> AHK hotkey name; main-row keys become scan codes
ComboError(combo) {
    try {
        ComboToHotkey(combo)
        return "no error"
    } catch ValueError as err
        return err.Message
}
Check("combo letter", ComboToHotkey("Alt+Shift+E"), "!+sc012")
Check("combo any order and case", ComboToHotkey(" shift + ALT + e "), "!+sc012")
Check("combo backtick", ComboToHotkey("Alt+``"), "!sc029")
Check("combo ctrl shift backtick", ComboToHotkey("Ctrl+Shift+``"), "^+sc029")
Check("combo ctrl alt", ComboToHotkey("Ctrl+Alt+I"), "^!sc017")
Check("combo all modifiers", ComboToHotkey("Win+Shift+Alt+Ctrl+1"), "^!+#sc002")
Check("combo named key", ComboToHotkey("Win+f1"), "#F1")
Check("combo key alias", ComboToHotkey("Ctrl+Esc"), "^Escape")
Check("combo function key alone", ComboToHotkey("F9"), "F9")
Check("combo error modifier", ComboError("Alt+Shft+G"), "unknown modifier 'Shft' (use Ctrl, Alt, Shift, Win)")
Check("combo error no key", ComboError("Alt+"), "no key after the last '+'")
Check("combo error typing key alone", ComboError("G"), "a typing key needs Ctrl, Alt or Win")
Check("combo error shift typing key", ComboError("Shift+G"), "a typing key needs Ctrl, Alt or Win")
Check("combo error twice", ComboError("Alt+alt+G"), "'alt' is given twice")
Check("combo error unknown key", ComboError("Ctrl+Foo"), "unknown key 'Foo'")
Check("combo error modifier as key", ComboError("Ctrl+Shift"), "the last part must be a key, not a modifier")
Check("hotkey to send", HotkeyToSend("!+sc014"), "!+{sc014}")
Check("hotkey to send named key", HotkeyToSend("^Escape"), "^{Escape}")

; MenuHotkey(): config combo, else the default; problems are noted, not thrown
CheckMenuHotkeys() {
    global MENU_KEYS
    Check("menu markup registered", MenuKeys.Taken.Count, 3)
    Check("menu link", MenuKeys.Taken["!+sc026"], "link")
    Check("menu config combo", MenuHotkey("t1", "test", (*) => 0), "^!+F11")
    MENU_KEYS["t2"] := "Ctrl+Alt+Shift+F11" ; Taken by t1: falls back to the default
    Check("menu duplicate uses default", MenuHotkey("t2", "test", (*) => 0), "^!+F12")
    MENU_KEYS["t3"] := "Bad+X"
    Check("menu bad combo uses default", MenuHotkey("t3", "test", (*) => 0), "^!+F10")
    MENU_KEYS["t4"] := ""
    Check("menu turned off", MenuHotkey("t4", "test", (*) => 0), "")
    MENU_KEYS["t5"] := "Ctrl+Alt+Shift+F12" ; Taken, and so is its default (F11)
    Check("menu no free combo", MenuHotkey("t5", "test", (*) => 0), "")
    MENU_KEYS.Delete("code") ; A config map without the name uses the default
    MenuKeys.Taken.Delete("!sc029")
    Check("menu missing name uses default", MenuHotkey("code", "markup", (*) => 0), "!sc029")
    MENU_KEYS["emojii"] := "Alt+Shift+E" ; A typo in config.ahk
    problems := MenuKeyProblems()
    Check("menu problem count", problems.Length, 5)
    Check("menu problem duplicate", problems[1], 't2: "Ctrl+Alt+Shift+F11": already used by t1')
    Check("menu problem bad", problems[2], 't3: "Bad+X": unknown modifier `'Bad`' (use Ctrl, Alt, Shift, Win)')
    Check("menu problem no default", problems[4], 't5: "Ctrl+Alt+Shift+F11" (the default): already used by t1')
    Check("menu problem typo", problems[5], 'emojii: no such menu (menus: code, codeblock, link, t1, t2, t3, t4, t5)')
}
CheckMenuHotkeys()

; ModuleOn(): the MODULES value, the default for a bad value or a missing name
CheckModules() {
    global MODULES
    Check("module on", ModuleOn("markup"), true)
    criterion := MenuKeys.Criteria["!+sc026"] ; Alt+Shift+L, a "markup" menu
    Check("menu condition follows module on", criterion(""), true)
    MODULES["markup"] := false
    Check("module off", ModuleOn("markup"), false)
    Check("menu condition follows module off", criterion(""), false)
    MODULES["markup"] := "off" ; Not true or false: the default (true)
    Check("module bad value uses default", ModuleOn("markup"), true)
    MODULES.Delete("markup")
    Check("module missing uses default", ModuleOn("markup"), true)
    MODULES["test"] := 0 ; false
    MODULES["markup"] := "off"
    MODULES["mouze"] := false
    problems := ModuleProblems()
    Check("module problem count", problems.Length, 2)
    Check("module problem value", problems[1], 'markup: "off" is not true or false')
    Check("module problem typo", problems[2], 'mouze: no such module (modules: markup, test)')
    MODULES := DEFAULT_MODULES.Clone()
}
CheckModules()

; GuardClipboard() swallows a clipboard error and throws any other on
BusyMenu() {
    throw Error("Can't open clipboard for writing.")
}
BrokenMenu() {
    throw Error("something else")
}
try {
    GuardClipboard(BusyMenu)
    Check("guard clipboard error", "swallowed", "swallowed")
} catch
    Check("guard clipboard error", "thrown", "swallowed")
try {
    GuardClipboard(BrokenMenu)
    Check("guard other error", "swallowed", "thrown")
} catch
    Check("guard other error", "thrown", "thrown")

FileAppend checks " checks, " failures " failed`n", "*"
ExitApp failures
