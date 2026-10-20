#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, StdOut   ; v2 warnings are load-time: run `/validate` to see them

/**
AHK Assistant: settings and globals; the features live in lib\*.ahk.
*/

SetTitleMatchMode 2
DetectHiddenWindows true
A_TrayMenu.ClickCount := 1
A_IconTip := "Assistant"
Persistent

;; Settings
; Defaults, then this machine's overrides (config.ahk is optional, not tracked)
#Include %A_ScriptDir%\config.default.ahk
#Include *i %A_ScriptDir%\config.ahk

;; Includes
#Include %A_ScriptDir%\lib\tools.ahk
#Include %A_ScriptDir%\lib\snippets-emoji.ahk
#Include %A_ScriptDir%\lib\snippets-datetime.ahk
#Include %A_ScriptDir%\lib\snippets-markup.ahk
#Include %A_ScriptDir%\lib\hotkeys.ahk
#Include %A_ScriptDir%\lib\apps.ahk
#Include %A_ScriptDir%\lib\window.ahk
#Include %A_ScriptDir%\lib\diag.ahk
#Include %A_ScriptDir%\lib\mouse.ahk
#Include %A_ScriptDir%\lib\script.ahk ; Always on: reload, hide a tooltip

;; Hotstrings
; #Hotstring EndChars -()[]{}:;'"/\,.?!`n `t    ; Default value
#Hotstring EndChars `n `t    ; only whitespace characters
#Include %A_ScriptDir%\lib\hotstrings.ahk ; Russian abbreviations: MODULES["hotstrings"]
