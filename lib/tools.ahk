;; Shared helpers

/** Show a tooltip for 1.5 seconds
*/
ShowToolTip(msgText) {
    ToolTip msgText
    SetTimer RemoveToolTip, -1500
}

RemoveToolTip() {
    ToolTip
}

/** True if the mouse cursor is over a window matching `winTitle`
*/
MouseIsOver(winTitle) {
    MouseGetPos , , &win
    return WinExist(winTitle " ahk_id " win)
}

/** Wait for one key press and return it as "scNNN"
The key is suppressed. Scan codes keep "press combo, then key" menus
independent of the keyboard layout. Modifier keys alone are ignored.
`hint` (the menu's keys, see ParseHint()) is shown in a hint window until a
key is pressed, unless the HINTS setting is off. `shift` is set to whether
Shift was held (the character can't tell Shift+4 from "$" on one layout
and ";" on another).
*/
GetOneKey(hint := "", &shift := false) {
    ih := InputHook("L1")
    ih.KeyOpt("{All}", "ES") ; All keys are [E]ndKeys and [S]uppressed
    ih.KeyOpt("{LShift}{RShift}{LCtrl}{RCtrl}{LAlt}{RAlt}{LWin}{RWin}", "-ES")
    ih.Start()
    hintGui := ""
    try {
        if (HINTS && hint != "")
            hintGui := ShowHint(hint)
        ih.Wait()
    } finally {
        ih.Stop() ; If ShowHint() threw, don't leave the hook swallowing keys
        if (hintGui)
            hintGui.Destroy()
    }
    shift := InStr(ih.EndMods, "+") > 0
    return Format("sc{:03X}", GetKeySC(ih.EndKey))
}

/** Split a menu hint into its title and rows of [key, label] cells
An optional first line "==Title==" is the title. Each other line is a row;
"|" separates cells, and a cell is "key: label" (the key ends at the first
":"). "|" and ":" are never key names (they are "+\" and "+;"), so ";" can
be a key. Spaces around keys and labels and blank lines don't matter. Throws
a ValueError for a cell with no key. A "+" (Shift) before a key is shown as
the Shift key arrow: "+v" -> "⇧v".
*/
ParseHint(hint) {
    title := ""
    rows := []
    for line in StrSplit(hint, "`n", "`r") {
        line := Trim(line)
        if (line = "")
            continue
        if (title = "" && rows.Length = 0 && RegExMatch(line, "^==\s*(.*?)\s*==$", &m)) {
            title := m[1]
            continue
        }
        cells := []
        for cell in StrSplit(line, "|") {
            if (Trim(cell) = "")
                continue
            colon := InStr(cell, ":")
            key := colon ? Trim(SubStr(cell, 1, colon - 1)) : ""
            if (key = "")
                throw ValueError("Menu hint: a cell needs 'key: label'", -1, Trim(cell))
            key := RegExReplace(key, "(^|,)\+(?=[^,])", "$1⇧")
            cells.Push([key, Trim(SubStr(cell, colon + 1))])
        }
        rows.Push(cells)
    }
    return {title: title, rows: rows}
}

/** Show a menu hint (see ParseHint()) near the mouse and return its Gui
The window doesn't take the focus. Keys and labels are aligned in columns.
*/
ShowHint(hint) {
    static style := {back: "202020", text: "E0E0E0", key: "FFC66D", size: 10
        , font: "Segoe UI", keyFont: "Segoe UI"
        , margin: 10, titleGap: 6, keyGap: 6, colGap: 18, rowGap: 2, offset: 16}
    static noPrefix := "+0x80" ; SS_NOPREFIX: show "&" as is
    parsed := ParseHint(hint)
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +Border +E0x08000000") ; WS_EX_NOACTIVATE
    g.BackColor := style.back
    y := style.margin
    width := 0
    if (parsed.title != "") {
        g.SetFont("s" style.size " bold c" style.text, style.font)
        title := g.AddText(noPrefix " x" style.margin " y" y, parsed.title)
        title.GetPos(, , &w, &h)
        width := w
        y += h + style.titleGap
    }

    ; Add every cell, then size each key and label column to its widest cell
    keyW := [], labelW := [], rows := []
    for row in parsed.rows {
        cells := []
        for i, cell in row {
            g.SetFont("s" style.size " bold c" style.key, style.keyFont)
            k := g.AddText(noPrefix " x0 y0", cell[1])
            g.SetFont("s" style.size " norm c" style.text, style.font)
            l := g.AddText(noPrefix " x0 y0", cell[2])
            k.GetPos(, , &kw)
            l.GetPos(, , &lw)
            while (keyW.Length < i) {
                keyW.Push(0)
                labelW.Push(0)
            }
            keyW[i] := Max(keyW[i], kw)
            labelW[i] := Max(labelW[i], lw)
            cells.Push([k, l])
        }
        rows.Push(cells)
    }
    for cells in rows {
        x := style.margin
        rowH := 0
        for pair in cells {
            pair[1].GetPos(, , , &kh)
            pair[2].GetPos(, , , &lh)
            rowH := Max(rowH, kh, lh)
        }
        for i, pair in cells {
            pair[1].GetPos(, , , &kh)
            pair[2].GetPos(, , , &lh)
            pair[1].Move(x, y + (rowH - kh) // 2)
            pair[2].Move(x + keyW[i] + style.keyGap, y + (rowH - lh) // 2)
            x += keyW[i] + style.keyGap + labelW[i] + style.colGap
        }
        width := Max(width, x - style.colGap - style.margin)
        y += rowH + style.rowGap
    }

    ; Size it, then place it below right of the mouse, inside its monitor
    g.Show("Hide w" (width + 2 * style.margin) " h" (y - style.rowGap + style.margin))
    WinGetPos , , &pw, &ph, g.Hwnd
    prevMode := A_CoordModeMouse
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my
    CoordMode "Mouse", prevMode
    MonitorGetWorkArea MonitorAt(mx, my), &left, &top, &right, &bottom
    x := Max(left, Min(mx + style.offset, right - pw))
    y := Max(top, Min(my + style.offset, bottom - ph))
    g.Show("NoActivate x" x " y" y)
    return g
}

/** Number of the monitor that holds the screen point x, y (the primary if none)
*/
MonitorAt(x, y) {
    loop MonitorGetCount() {
        MonitorGet A_Index, &left, &top, &right, &bottom
        if (x >= left && x < right && y >= top && y < bottom)
            return A_Index
    }
    return MonitorGetPrimary()
}

/** US-layout name of a key given as "scNNN" ("v" for sc02F, "/" for sc035)
Use it instead of GetKeyName() in menus: GetKeyName() names a letter or
punctuation key by the active layout, so sc02F is "м" in the Russian one.
Keys outside the main rows (Esc, Up, NumpadAdd, ...) keep the same name in
every layout, so they come from GetKeyName().
*/
KeyNameUS(key) {
    sc := Integer("0x" SubStr(key, 3))
    for first, chars in KeyRowsUS() {
        if (sc >= first && sc < first + StrLen(chars))
            return SubStr(chars, sc - first + 1, 1)
    }
    return GetKeyName(key)
}

/** Scan code ("sc022") of a main-row key given by its US character ("g"),
or "" for any other key. The reverse of KeyNameUS().
*/
ScanCodeUS(char) {
    char := StrLower(char)
    if (StrLen(char) != 1)
        return ""
    for first, chars in KeyRowsUS() {
        pos := InStr(chars, char, true)
        if (pos)
            return Format("sc{:03X}", first + pos - 1)
    }
    return ""
}

/** The main keyboard rows: first scan code -> US characters, left to right
*/
KeyRowsUS() {
    static rows := Map(0x02, "1234567890-=", 0x10, "qwertyuiop[]"
        , 0x1E, "asdfghjkl;'", 0x29, "``", 0x2B, "\", 0x2C, "zxcvbnm,./")
    return rows
}

; - - -
;; - Menu hotkeys

/** AHK hotkey name of a readable combo: "Alt+Shift+G" -> "!+sc022"
Modifiers are Ctrl, Alt, Shift and Win, in any order and letter case; the
last part is the key. A main-row key (letter, digit, punctuation) becomes
its scan code, so the hotkey works in any keyboard layout, and needs Ctrl,
Alt or Win (alone, or with only Shift, it would block typing). Other keys
use their AHK name (F1, Esc, Space, Numpad1). Throws a ValueError.
*/
ComboToHotkey(combo) {
    static modChars := Map("ctrl", "^", "alt", "!", "shift", "+", "win", "#")
    parts := StrSplit(Trim(combo), "+", " `t")
    key := parts.Pop()
    if (key = "")
        throw ValueError("no key after the last '+'", -1, combo)
    mods := ""
    for part in parts {
        modChar := modChars.Get(StrLower(part), "")
        if (modChar = "")
            throw ValueError("unknown modifier '" part "' (use Ctrl, Alt, Shift, Win)", -1, combo)
        if (InStr(mods, modChar))
            throw ValueError("'" part "' is given twice", -1, combo)
        mods .= modChar
    }
    name := ScanCodeUS(key)
    if (name != "") {
        if (RegExReplace(mods, "\+") = "")
            throw ValueError("a typing key needs Ctrl, Alt or Win", -1, combo)
    } else {
        name := GetKeyName(key)
        if (name = "")
            throw ValueError("unknown key '" key "'", -1, combo)
        if (RegExMatch(name, "i)^[LR]?(Control|Ctrl|Alt|Shift|Win)$"))
            throw ValueError("the last part must be a key, not a modifier", -1, combo)
    }
    ordered := "" ; One order, so that "Shift+Alt+G" and "Alt+Shift+G" match
    for modChar in ["^", "!", "+", "#"] {
        if (InStr(mods, modChar))
            ordered .= modChar
    }
    return ordered name
}

/** Send form of a hotkey name, to pass the combo on: "!+sc014" -> "!+{sc014}"
*/
HotkeyToSend(hotkeyName) {
    return RegExReplace(hotkeyName, "^([\^!+#]*)(.+)$", "$1{$2}")
}

/** State of the menu hotkeys: the ones taken, the module condition of each,
and the config problems found
*/
class MenuKeys {
    static Taken := Map()    ; AHK hotkey name -> menu name
    static Criteria := Map() ; AHK hotkey name -> its HotIf callback
    static Problems := []
}

/** Register the hotkey that opens menu `name` (a key of MENU_KEYS) of
module `module` (a key of MODULES)
The combo comes from MENU_KEYS (config.ahk), or DEFAULT_MENU_KEYS if the
user's map lacks the name; "" turns the menu off. A bad combo, or one that
another menu already uses, is noted for ReportConfig() and the default is
used instead. The hotkey is active only while its module is on. Returns the
AHK hotkey name, or "" if the menu has none.
*/
MenuHotkey(name, module, callback) {
    static reportSet := false
    if (!reportSet) {
        reportSet := true
        SetTimer ReportConfig, -1 ; After startup, once every menu is registered
    }
    defaultCombo := DEFAULT_MENU_KEYS[name] ; An unknown name is a bug: let it throw
    DEFAULT_MODULES[module]                 ; The same for an unknown module
    combo := MENU_KEYS.Get(name, defaultCombo)
    if (combo = "")
        return ""
    hotkeyName := TryMenuCombo(name, combo, module, callback)
    if (hotkeyName = "" && combo != defaultCombo)
        hotkeyName := TryMenuCombo(name, defaultCombo, module, callback, " (the default)")
    return hotkeyName
}

/** Register `combo` for menu `name`; on failure note why and return ""
*/
TryMenuCombo(name, combo, module, callback, which := "") {
    criterion := (*) => ModuleOn(module)
    try {
        hotkeyName := ComboToHotkey(combo)
        if (MenuKeys.Taken.Has(hotkeyName))
            throw ValueError("already used by " MenuKeys.Taken[hotkeyName], -1, combo)
        HotIf criterion
        try
            Hotkey hotkeyName, callback, "On"
        finally
            HotIf
    } catch as err {
        MenuKeys.Problems.Push(name ': "' combo '"' which ': ' err.Message)
        return ""
    }
    MenuKeys.Taken[hotkeyName] := name
    MenuKeys.Criteria[hotkeyName] := criterion
    return hotkeyName
}

/** Pass a menu combo on to the active app, for a key that isn't in the menu
`hotkeyName` is the menu's hotkey (the callback's parameter). The hotkey is
off while the combo is sent, so it doesn't open the menu again.
*/
PassMenuCombo(hotkeyName) {
    HotIf MenuKeys.Criteria[hotkeyName]
    try {
        Hotkey hotkeyName, "Off"
        Send HotkeyToSend(hotkeyName)
        Hotkey hotkeyName, "On"
    } finally
        HotIf
}

/** Problems of the menu hotkey settings: the ones found while registering,
and MENU_KEYS names that no menu has (a typo in config.ahk)
*/
MenuKeyProblems() {
    problems := MenuKeys.Problems.Clone()
    for name in MENU_KEYS {
        if (!DEFAULT_MENU_KEYS.Has(name))
            problems.Push(name ': no such menu (menus: ' JoinKeys(DEFAULT_MENU_KEYS) ')')
    }
    return problems
}

; - - -
;; - Modules

/** True if module `name` (a key of MODULES) is on
Used in #HotIf, so it runs on every press of a module's keys. A value other
than true or false counts as the default (and is reported at startup).
*/
ModuleOn(name) {
    value := MODULES.Get(name, DEFAULT_MODULES[name])
    return (value == true || value == false) ? value : DEFAULT_MODULES[name]
}

/** Problems of the MODULES setting: unknown names and values that aren't
true or false
*/
ModuleProblems() {
    problems := []
    for name, value in MODULES {
        if (!DEFAULT_MODULES.Has(name))
            problems.Push(name ': no such module (modules: ' JoinKeys(DEFAULT_MODULES) ')')
        else if !(value == true || value == false)
            problems.Push(name ': "' value '" is not true or false')
    }
    return problems
}

/** Show the problems of MENU_KEYS, MODULES and WINDOW_STEPS, if any, in one
message box
*/
ReportConfig() {
    text := ""
    for problem in MenuKeyProblems()
        text .= "`n- MENU_KEYS " problem
    for problem in ModuleProblems()
        text .= "`n- MODULES " problem
    for problem in WindowStepsProblems()
        text .= "`n- WINDOW_STEPS " problem
    if (text != "")
        MsgBox "Settings in config.ahk:" text, "Assistant: settings", "Icon!"
}

/** The keys of a Map, joined with ", "
*/
JoinKeys(items) {
    text := ""
    for name in items
        text .= (text = "" ? "" : ", ") name
    return text
}

/** Number of the monitor whose work area holds the horizontal middle of
window `hwnd` (default: the active window); the primary monitor if none
does or there is no such window
*/
GetMonitor(hwnd := 0) {
    try
        WinGetPos &winX, , &winW, , hwnd ? hwnd : "A"
    catch
        return MonitorGetPrimary()
    winMid := winX + winW / 2
    loop MonitorGetCount() {
        MonitorGetWorkArea A_Index, &monLeft, , &monRight
        if (winMid >= monLeft && winMid < monRight)
            return A_Index
    }
    return MonitorGetPrimary()
}

;; - Clipboard

/** Copy the current selection and return it as text ("" if none)
The clipboard as it was before the copy comes back in `saved` (all
formats, for RestoreClipboard) and in `clipText` (as text).
*/
CopySelection(&saved, &clipText, timeout := 0.5) {
    SaveClipboard(&saved, &clipText)
    A_Clipboard := ""
    Send "^c"
    ClipWait timeout
    return A_Clipboard
}

/** Keep the clipboard in `saved` (all formats, for RestoreClipboard) and
`clipText` (as text), without copying anything
For menu keys that only use the clipboard: no Ctrl+C reaches the app (in a
terminal, Ctrl+C with nothing selected interrupts the program).
*/
SaveClipboard(&saved, &clipText) {
    saved := ClipboardAll()
    clipText := A_Clipboard
}

/** Paste `text` through the clipboard (Shift+Ins)
*/
PasteText(text) {
    A_Clipboard := text
    Send "+{Ins}"
    Sleep DELAY
}

/** Put back the clipboard saved by CopySelection()
*/
RestoreClipboard(saved) {
    Sleep DELAY ; let the target app finish reading the clipboard
    A_Clipboard := saved
}

/** Run `menu`, a hotkey body that works with the clipboard
Another program (a clipboard manager, a remote desktop) can keep the
clipboard open: v2 then throws "Can't open clipboard" after retrying for a
second. That shows a tooltip instead of an error dialog; any other error
is thrown on.
*/
GuardClipboard(menu) {
    try
        menu()
    catch Error as e {
        if !InStr(e.Message, "clipboard")
            throw e
        ShowToolTip("Clipboard is busy, try again")
    }
}

;; - Markup

/** Markup flavour for the active window: "confluence", "jira" or "markdown"
*/
GetMarkupTarget() {
    service := GetActiveService()
    return (service = "confluence" || service = "jira") ? service : "markdown"
}

;; - Active app and service
; A window has one app (the program, matched by class or exe) and at most
; one service (the site or document, matched by title): Confluence in
; Firefox is app "firefox" and service "confluence". Add new apps and
; services to the rule tables only.

/** Alias of the program that owns the active window, or "general"
*/
GetActiveApp() {
    return MatchActiveWin(AppRules())
}

/** True if the active window belongs to the program `alias`
*/
IsActiveApp(alias) {
    return MatchActiveWin(AppRules(), alias) = alias
}

/** Alias of the service shown in the active window, or "general"
*/
GetActiveService() {
    return MatchActiveWin(ServiceRules())
}

/** True if the active window shows the service `alias`
*/
IsActiveService(alias) {
    return MatchActiveWin(ServiceRules(), alias) = alias
}

/** Programs. First match wins, so exact rules (class, exe) come first.
Each rule has an alias and regexes on the window's title, winClass and/or
exe (process name); all given regexes must match.
*/
AppRules() {
    static rules := [
        {alias: "moba-tty", winClass: "^CPopMoTTY$"},   ; MobaXterm PuTTY-style terminal
        {alias: "mobaxterm", winClass: "^(TFormDetachedTab|TMobaXtermForm)$"},
        {alias: "adventure", winClass: "^AutoHotkeyGUI$"}, ; Adventure IDE (any AHK GUI)
        {alias: "firefox", exe: "i)^firefox\.exe$"},
        {alias: "mattermost", exe: "i)^mattermost\.exe$"},
        {alias: "outlook", exe: "i)^outlook\.exe$"},
        {alias: "burp", title: "Burp Suite|Intruder attack|Select WebSocket"}, ; plain Java: title only
    ]
    return rules
}

/** Services, matched by title. Same rule format as AppRules().
*/
ServiceRules() {
    static rules := [
        {alias: "confluence", title: "(- Confluence(\s|$))|^(Wiki|Confl)$"}, ; + renamed windows
        {alias: "jira", title: "i)Jira$"}, ; tab titles end with "- Jira" or "- <Company> JIRA"
    ]
    return rules
}

/** Alias of the first rule that matches the active window, or "general".
With `alias`, only the rules named `alias` are tried.
*/
MatchActiveWin(rules, alias := "") {
    title := winClass := exe := ""
    if hwnd := WinExist("A") {
        try {   ; the window may close, or deny access to its process
            title := WinGetTitle(hwnd)
            winClass := WinGetClass(hwnd)
            exe := WinGetProcessName(hwnd)
        }
    }
    return MatchWinRules(rules, title, winClass, exe, alias)
}

/** MatchActiveWin() for the given window data (testable without windows)
*/
MatchWinRules(rules, title, winClass, exe, alias := "") {
    known := (alias = "")
    for rule in rules {
        if (alias != "" && rule.alias != alias)
            continue
        known := true
        if rule.HasOwnProp("title") && !RegExMatch(title, rule.title)
            continue
        if rule.HasOwnProp("winClass") && !RegExMatch(winClass, rule.winClass)
            continue
        if rule.HasOwnProp("exe") && !RegExMatch(exe, rule.exe)
            continue
        return rule.alias
    }
    if !known
        throw ValueError("Unknown app or service alias: " alias)
    return "general"
}
