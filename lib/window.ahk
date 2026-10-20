;; Window management

#HotIf ModuleOn("window")
;; - Window properties: AlwaysOnTop
Launch_App1::ontopToggle("A")

;; - Window size and position

; Numpad layout: 8/2/4/6 = halves (like the arrows), 7/9/1/3 = quarters
^#Numpad1::WindowMove("BL")     ; Bottom-left quarter
^#Numpad2::WindowMove("Down")   ; Lower half
^#Numpad3::WindowMove("BR")     ; Bottom-right quarter
^#Numpad4::WindowMove("Left")   ; Left half
^#Numpad5::WindowMove("Toggle") ; Maximize, or restore if maximized
^#Numpad6::WindowMove("Right")  ; Right half
^#Numpad7::WindowMove("TL")     ; Top-left quarter
^#Numpad8::WindowMove("Up")     ; Upper half
^#Numpad9::WindowMove("TR")     ; Top-right quarter

^#Up::WindowMove("Up")          ; Resize and move to the upper half of screen
^#Down::WindowMove("Down")      ; Resize and move to the lower half of screen
^#Left::WindowMove("Left")      ; Resize and move to the left half of screen
^#Right::WindowMove("Right")    ; Resize and move to the right half of screen
#Up::WindowMove("Max")          ; Maximize window
#Down::WindowMove("Min")        ; [Restore] -> Minimize window

#HotIf

; - - -
;; Functions

/** On Top Toggle
*/
ontopToggle(winTitle) {
    if !(hwnd := WinExist(winTitle)) {
        MsgBox "Window not found.`n`n" winTitle, "Error", 48
        return
    }
    WinSetAlwaysOnTop -1, hwnd
    isOnTop := WinGetExStyle(hwnd) & 0x8 ; WS_EX_TOPMOST
    TrayTip WinGetTitle(hwnd) "`n`nPress again to switch setting.", isOnTop ? "ON TOP - ON:" : "ON TOP - OFF:"
    SoundBeep 1500
}

/** Move the active window to region `dir` of its monitor's work area
"Up"/"Down"/"Left"/"Right": halves; "TL"/"TR"/"BL"/"BR": quarters;
"Max": maximize; "Min": restore if maximized, else minimize;
"Toggle": maximize, or restore if maximized.
*/
WindowMove(dir) {
    ; Target the active window by its ID: its title could match other windows
    if !(hwnd := WinExist("A"))
        return
    MonitorGetWorkArea GetMonitor(hwnd), &waLeft, &waTop, &waRight, &waBottom
    minMax := WinGetMinMax(hwnd)

    if (minMax = 1 && dir != "Max") {
        ; Restore if window state is Maximized and dir != Max
        ; ("Toggle" stops here: RegionRect() has no case for it)
        WinRestore hwnd
        Sleep 50

    } else if (dir = "Min" && minMax = 0) {
        ; Minimize if windows state is Restored
        WinMinimize hwnd
        Sleep 50
        return

    } else if (dir = "Max" || dir = "Toggle") {
        ; Maximize if windows state is Restored
        if (minMax = 0)
            WinMaximize hwnd
        Sleep 50
        return
    }

    if (rect := RegionRect(dir, waLeft, waTop, waRight, waBottom))
        WinMove rect.x, rect.y, rect.w, rect.h, hwnd
}

/** Window rectangle {x, y, w, h} for region `dir` of a work area, or ""
for other values. The window overlaps the edges by `winBorder` px to
hide its invisible resize borders.
*/
RegionRect(dir, waLeft, waTop, waRight, waBottom, winBorder := 10) {
    waW := Abs(waRight - waLeft)
    waH := Abs(waBottom - waTop)
    halfW := Floor(waW / 2)
    halfH := Floor(waH / 2)
    switch dir {
    case "Up":
        return {x: waLeft - winBorder, y: waTop, w: waW + 2 * winBorder, h: halfH + winBorder}
    case "Down":
        return {x: waLeft - winBorder, y: waTop + halfH, w: waW + 2 * winBorder, h: halfH + winBorder}
    case "Left":
        return {x: waLeft - winBorder, y: waTop, w: halfW + 2 * winBorder, h: waH + winBorder}
    case "Right":
        return {x: waLeft + halfW - winBorder, y: waTop, w: halfW + 2 * winBorder, h: waH + winBorder}
    case "TL", "TR", "BL", "BR": ; Quarters: start top-left, shift right/down
        return {x: waLeft - winBorder + (InStr(dir, "R") ? halfW : 0)
            , y: waTop + (InStr(dir, "B") ? halfH : 0)
            , w: halfW + 2 * winBorder, h: halfH + winBorder}
    }
    return ""
}
