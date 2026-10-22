#Requires AutoHotkey v2.0
#Warn All, StdOut
; Checks that every module in lib/ can be switched off (MODULES): each
; hotkey and hotstring of a module file is under a #HotIf that contains
; ModuleOn("<its module>"), each file ends with a bare #HotIf, every
; MenuHotkey() and SettingHotkey() call names the file's module, and MODULES in
; config.default.ahk lists exactly the modules of lib/. Prints failures and
; a summary, exits with the number of failures (0 = OK):
;   AutoHotkey64.exe /ErrorStdOut tests\modules.ahk

; lib/ file -> its module; "" = always on (not in MODULES). A new file in
; lib/ must be added here.
fileModules := Map(
    "tools.ahk", "", "script.ahk", "",
    "snippets-emoji.ahk", "emoji", "snippets-datetime.ahk", "datetime",
    "snippets-markup.ahk", "markup", "hotkeys.ahk", "hotkeys",
    "apps.ahk", "apps", "window.ahk", "window", "diag.ahk", "diag",
    "mouse.ahk", "mouse", "hotstrings.ahk", "hotstrings"
)

checks := 0
failures := 0

Fail(text) {
    global failures
    failures++
    FileAppend "FAIL " text "`n", "*"
}

/** Check one module file; returns the number of definitions checked
*/
CheckFile(path, fileName, module) {
    global checks
    guard := 'ModuleOn("' module '")'
    condition := ""        ; The current #HotIf condition, "" for none
    inComment := false ; Inside a /* … */ block
    defs := 0
    for line in StrSplit(StrReplace(FileRead(path, "UTF-8"), "`r"), "`n") {
        where := fileName ":" A_Index
        if (inComment) {
            inComment := !InStr(line, "*/")
            continue
        }
        if (SubStr(LTrim(line), 1, 2) = "/*") {
            inComment := !InStr(line, "*/")
            continue
        }
        if (RegExMatch(line, "^#HotIf\b\s*(.*)$", &m)) {
            condition := RegExReplace(m[1], "\s+;.*$")
            continue
        }
        if (RegExMatch(line, '^(MenuHotkey|SettingHotkey)\(("\w+", \w+, \w+, )?"\w+", "(\w+)"', &m)) {
            checks++
            if (m[3] != module)
                Fail(where ": " m[1] "() names module " m[3] ", the file's is " module)
            continue
        }
        ; A hotkey ("^!x::", "~Esc::", "a & b::") or a hotstring ("::btw::", ":*:x::");
        ; a line starting with ";" is a comment
        if (SubStr(line, 1, 1) = ";" || !RegExMatch(line, "^(:[^:\s]*:\S.*?::|[~*$<>!^+#]*\S+?( & \S+)?( up)?::)"))
            continue
        checks++, defs++
        if (!InStr(condition, guard))
            Fail(where ": not under #HotIf " guard ": " Trim(line))
    }
    checks++
    if (condition != "")
        Fail(fileName ": ends inside #HotIf " condition " (end it with a bare #HotIf)")
    return defs
}

Main() {
    global checks
    ; MODULES in config.default.ahk
    configModules := Map()
    inMap := false
    for line in StrSplit(StrReplace(FileRead(A_ScriptDir "\..\config.default.ahk", "UTF-8"), "`r"), "`n") {
        if (RegExMatch(line, "^MODULES := Map\("))
            inMap := true
        else if (inMap && SubStr(line, 1, 1) = ")")
            break
        else if (inMap && RegExMatch(line, '^\s*"(\w+)",', &m))
            configModules[m[1]] := true
    }

    seen := Map()
    loop files A_ScriptDir "\..\lib\*.ahk" {
        checks++
        if (!fileModules.Has(A_LoopFileName)) {
            Fail(A_LoopFileName ": not in fileModules (tests/modules.ahk): which module is it?")
            continue
        }
        module := fileModules[A_LoopFileName]
        if (module = "")
            continue
        seen[module] := true
        defs := CheckFile(A_LoopFileFullPath, A_LoopFileName, module)
        FileAppend Format("  {:-24} {:-11} {} hotkeys and hotstrings`n", A_LoopFileName, module, defs), "*"
    }
    for module in seen {
        checks++
        if (!configModules.Has(module))
            Fail("module " module " is missing from MODULES in config.default.ahk")
    }
    for module in configModules {
        checks++
        if (!seen.Has(module))
            Fail("MODULES in config.default.ahk lists " module ", but no lib/ file has it")
    }
}
Main()
FileAppend checks " checks, " failures " failed`n", "*"
ExitApp failures
