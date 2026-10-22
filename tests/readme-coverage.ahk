#Requires AutoHotkey v2.0
#Warn All, StdOut
; Compares the hotkeys defined in Assistant.ahk and lib/, and the default
; menu hotkeys (MENU_KEYS in config.default.ahk), with the ones the README
; mentions. Run it by hand after adding, changing or removing a hotkey:
;   AutoHotkey64.exe /ErrorStdOut tests\readme-coverage.ahk
; Prints every hotkey of the code (ok / MISSING) and then the README
; notations that match no hotkey of the code, for a manual check (they can
; be keys the script sends, menu triggers or stale entries). The exit code
; is the number of hotkeys missing from the README (0 = OK).
;
; Hotkeys are compared by modifiers and key, in any order and letter case.
; README notations understood: "Ctrl+Win+Numpad8/2/4/6", "Ctrl+Win+1…5",
; "Ctrl+Win+←/→". A hotkey without modifiers counts as documented if the
; README names its key (or an alias, below).

; Key of the code -> text that documents it in the README
aliases := Map("WheelUp", "Wheel", "WheelDown", "Wheel")

modOrder := ["Ctrl", "LCtrl", "RCtrl", "Alt", "LAlt", "RAlt"
    , "Shift", "LShift", "RShift", "Win", "LWin", "RWin"]
arrows := Map("←", "Left", "→", "Right", "↑", "Up", "↓", "Down")

/** "Ctrl+Alt+R" with the modifiers in a fixed order, as one comparable name
*/
CanonName(mods, key) {
    global modOrder
    result := ""
    for modName in modOrder {
        for item in mods {
            if (item = modName)
                result .= modName "+"
        }
    }
    return result (arrows.Has(key) ? arrows[key] : key)
}

/** Modifiers of a hotkey prefix such as "~^!" or ">^" ("RCtrl")
*/
PrefixMods(prefix) {
    modList := []
    side := ""
    loop parse prefix {
        switch A_LoopField {
        case "<":
            side := "L"
        case ">":
            side := "R"
        case "#":
            modList.Push(side "Win"), side := ""
        case "^":
            modList.Push(side "Ctrl"), side := ""
        case "!":
            modList.Push(side "Alt"), side := ""
        case "+":
            modList.Push(side "Shift"), side := ""
        }
    }
    return modList
}

/** Keys of a README key part: "Numpad8/2/4/6", "1…5", "←/→", "R"
*/
ExpandKeys(part) {
    keys := []
    if RegExMatch(part, "^(\d)…(\d)$", &range) {
        loop range[2] - range[1] + 1
            keys.Push(range[1] + A_Index - 1)
        return keys
    }
    pieces := StrSplit(part, "/")
    prefix := RegExReplace(pieces[1], "\d+$", "")
    numbered := RegExMatch(pieces[1], "\d$") && prefix != ""
    for piece in pieces {
        if (numbered && A_Index > 1 && StrLen(piece) = 1)
            piece := prefix piece
        keys.Push(piece)
    }
    return keys
}

; Hotkeys of the code: canonical name -> "file:line", and the bare ones
codeKeys := Map()
codeKeys.CaseSense := false
bareKeys := Map() ; key -> "file:line", hotkeys without modifiers
files := [A_ScriptDir "\..\Assistant.ahk"]
loop files A_ScriptDir "\..\lib\*.ahk" {
    if (A_LoopFileName != "hotstrings.ahk") ; dormant
        files.Push(A_LoopFileFullPath)
}
for path in files {
    SplitPath path, &fileName
    inComment := false ; inside a /* … */ block
    for line in StrSplit(StrReplace(FileRead(path, "UTF-8"), "`r"), "`n") {
        if inComment {
            inComment := !InStr(line, "*/")
            continue
        }
        if (SubStr(line, 1, 2) = "/*") {
            inComment := !InStr(line, "*/")
            continue
        }
        if !RegExMatch(line, "^([~*$<>!^+#]*)(``|[A-Za-z0-9_]+)::", &m)
            continue
        mods := PrefixMods(m[1])
        name := CanonName(mods, m[2])
        where := fileName ":" A_Index
        if !codeKeys.Has(name)
            codeKeys[name] := where
        if (mods.Length = 0 && !bareKeys.Has(m[2]))
            bareKeys[m[2]] := where
    }
}

; Configurable hotkeys: registered at startup from MENU_KEYS and MOUSE_KEYS
; ("Alt+Shift+E", "XButton1")
inMap := false
for line in StrSplit(StrReplace(FileRead(A_ScriptDir "\..\config.default.ahk", "UTF-8"), "`r"), "`n") {
    if (RegExMatch(line, "^(MENU|MOUSE)_KEYS := Map\(")) {
        inMap := true
    } else if (inMap && SubStr(line, 1, 1) = ")") {
        inMap := false
    } else if (inMap && RegExMatch(line, '"(\w+)", *"([^"]+)"', &m)) {
        parts := StrSplit(StrReplace(m[2], "````", "``"), "+") ; "Alt+``" is Alt+`
        key := parts.Pop()
        name := CanonName(parts, key)
        where := "config.default.ahk:" A_Index " (" m[1] ")"
        if !codeKeys.Has(name)
            codeKeys[name] := where
        if (parts.Length = 0 && !bareKeys.Has(key))
            bareKeys[key] := where
    }
}

; Hotkeys of the README
readme := FileRead(A_ScriptDir "\..\README.md", "UTF-8")
readmeKeys := Map()
readmeKeys.CaseSense := false
pos := 1
while RegExMatch(readme, "((?:[LR]?(?:Ctrl|Alt|Shift|Win)\+)+)(``|[^\s|,*``()`"]+)", &m, pos) {
    pos := m.Pos + m.Len
    mods := StrSplit(RTrim(m[1], "+"), "+")
    for key in ExpandKeys(RTrim(m[2], ".;:")) {
        name := CanonName(mods, key)
        if !readmeKeys.Has(name)
            readmeKeys[name] := true
    }
}

missing := 0
FileAppend "Hotkeys in the code, and whether the README mentions them:`n", "*"
for name, where in codeKeys {
    if bareKeys.Has(name) {
        word := aliases.Has(name) ? aliases[name] : name
        found := InStr(readme, word)
    } else {
        found := readmeKeys.Has(name)
    }
    if !found
        missing++
    FileAppend Format("  {:-7} {:-24} {}`n", found ? "ok" : "MISSING", name, where), "*"
}

FileAppend "`nIn the README, but no such hotkey in the code (check by hand):`n", "*"
extra := 0
for name in readmeKeys {
    if !codeKeys.Has(name) {
        extra++
        FileAppend "  " name "`n", "*"
    }
}
if (extra = 0)
    FileAppend "  none`n", "*"

FileAppend "`n" codeKeys.Count " hotkeys in the code, " missing " missing from the README`n", "*"
ExitApp missing
