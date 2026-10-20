;; Script control
; Always on: not a module in MODULES, so a switched-off module can be turned
; back on with a reload.

;; - Reload current script
^!r:: {
    if MsgBox("Do you want to reload current script?", , 4) != "Yes"
        return
    Reload
    Sleep 2000 ; If successful, the reload will close this instance during the Sleep
}

;; - Reset ToolTip
^!+r::ToolTip
