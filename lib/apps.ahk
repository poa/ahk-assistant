; - - -
;; App specific mappings
; Apps and services: AppRules() / ServiceRules() in lib/tools.ahk.
; Sections are sorted by app name. The foobar2000 and VirtuaWin keys work
; in any window: they forward a combo to the app's own global hotkey.

;; - Adventure IDE, Burp Suite, Confluence
; Ctrl+Ins, Shift+Ins and Shift+Del to Ctrl+C/V/X
#HotIf ModuleOn("apps") && (IsActiveApp("adventure") or IsActiveApp("burp") or IsActiveService("confluence"))
+Ins::Send "^v"
^Ins::Send "^c"
+Del::Send "^x"
#HotIf

;; - foobar2000
; Win+Alt+B sends Win+Alt+Shift+B, foobar2000's global hotkey
#HotIf ModuleOn("apps")
#!b::Send "{Blind}#!+b"
#HotIf

;; - Mattermost
; Ctrl+Enter sends the message, Enter adds a new line
#HotIf ModuleOn("apps") && (IsActiveApp("mattermost"))
Enter::Send "+{Enter}"
^Enter::Send "{Enter}"
#HotIf

;; - MobaXterm
/**
Emulate paste by ShiftIns
*/
#HotIf ModuleOn("apps") && (IsActiveApp("mobaxterm"))
+Ins::Send "^v"
#HotIf

#HotIf ModuleOn("apps") && (IsActiveApp("moba-tty"))
^v::Send "{MButton}"
+Ins::Send "{MButton}"
#HotIf

;; - MS Outlook
/**
Find within letter body by Ctrl+F
*/
#HotIf ModuleOn("apps") && (IsActiveApp("outlook"))
^f:: {
    SetKeyDelay 100
    Send "^g"
    Send "!d"
}
#HotIf

;; - VirtuaWin
/*
Disable Explorer hotkey `Win+Alt+{Number}` and map it to `Ctrl+Win+Alt+{Number}` to move current window to {Number} Desktop of VirtuaWin
*/
#HotIf ModuleOn("apps")
^#1::Send "{Blind}^#!1"
^#2::Send "{Blind}^#!2"
^#3::Send "{Blind}^#!3"
^#4::Send "{Blind}^#!4"
^#5::Send "{Blind}^#!5"
#HotIf
