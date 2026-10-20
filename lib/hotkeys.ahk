;; Global hotkeys

#HotIf ModuleOn("hotkeys")
;; - Override Win+Shift+K to show BT Connections
#+k::Run "ms-actioncenter:controlcenter/bluetooth"

;; Power tools + Window menu
; ToDo: Alt+Space → PowerToys Run, Win+Alt+Space → native window menu.
; An earlier draft didn't work as expected.

; - - -
;; General mappings
;; - Mouse Scroll over the taskbar. Change volume
#HotIf ModuleOn("hotkeys") && (MouseIsOver("ahk_class Shell_TrayWnd") or MouseIsOver("ahk_class Shell_SecondaryTrayWnd"))
WheelUp::Send "{Volume_Up}"
WheelDown::Send "{Volume_Down}"
#HotIf ModuleOn("hotkeys")

;; - NumPad: Send dot by all means (instead of comma)
NumpadDot::Send "."

;; - PrintScreen to Insert (for notebooks)
;PrintScreen::Ins
;^PrintScreen::^Ins
;+PrintScreen::+Ins
#HotIf
