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

; Arrows: each press steps through WINDOW_STEPS (2/3, 1/2, 1/3 of the screen)
^#Up::WindowStep("Up")          ; Top part of the screen
^#Down::WindowStep("Down")      ; Bottom part of the screen
^#Left::WindowStep("Left")      ; Left part of the screen
^#Right::WindowStep("Right")    ; Right part of the screen
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
        MoveWindowFrame(hwnd, rect)
}

/** Move window `hwnd` so that its visible frame fills `rect` {x, y, w, h}
Windows 10/11 windows have invisible resize borders (7 px at 100% scaling:
left, right and bottom), so the outer rectangle is the visible one plus
those borders, measured for this window (none for a window without them).
Moving to a monitor with another DPI changes the borders, so a second
pass corrects the size if the first missed.
*/
MoveWindowFrame(hwnd, rect) {
    loop 2 {
        b := FrameBorders(hwnd)
        WinMove rect.x - b.left, rect.y - b.top
            , rect.w + b.left + b.right, rect.h + b.top + b.bottom, hwnd
        f := FrameBorders(hwnd)
        if (f.left = b.left && f.top = b.top && f.right = b.right && f.bottom = b.bottom)
            return
    }
}

/** Invisible borders {left, top, right, bottom} of window `hwnd`: the gap
between its outer rectangle and its visible frame (DWM's extended frame
bounds); all 0 if DWM doesn't report the frame
*/
FrameBorders(hwnd) {
    WinGetPos &x, &y, &w, &h, hwnd
    frame := Buffer(16)
    if (DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9 ; DWMWA_EXTENDED_FRAME_BOUNDS
            , "Ptr", frame, "UInt", 16) != 0)
        return {left: 0, top: 0, right: 0, bottom: 0}
    return {left: NumGet(frame, 0, "Int") - x, top: NumGet(frame, 4, "Int") - y
        , right: x + w - NumGet(frame, 8, "Int"), bottom: y + h - NumGet(frame, 12, "Int")}
}

/** Step the active window through WINDOW_STEPS of its monitor's work area,
toward `dir` ("Up", "Down", "Left", "Right")
A repeated press (same window, same arrow, window untouched since) takes
the next size and wraps after the last. Anything else starts at the
first size. A maximized window is restored first.
*/
WindowStep(dir) {
    static last := {hwnd: 0, dir: "", step: 0, rect: ""}
    if !(hwnd := WinExist("A"))
        return
    steps := WindowSteps()
    try {
        WinGetPos &x, &y, &w, &h, hwnd
        isRepeat := (hwnd = last.hwnd && dir = last.dir && (x " " y " " w " " h) = last.rect)
        step := NextWindowStep(isRepeat, last.step, steps.Length)
        MonitorGetWorkArea GetMonitor(hwnd), &waLeft, &waTop, &waRight, &waBottom
        if (WinGetMinMax(hwnd) = 1) {
            WinRestore hwnd
            Sleep 50
        }
        rect := RegionRect(dir, waLeft, waTop, waRight, waBottom, steps[step])
        MoveWindowFrame(hwnd, rect)
        ; What the window really got: apps may round sizes or keep a minimum
        WinGetPos &x, &y, &w, &h, hwnd
    } catch
        return ; The window closed or denied access
    last := {hwnd: hwnd, dir: dir, step: step, rect: x " " y " " w " " h}
}

/** Step number (1-based) for the next press: the one after `lastStep` for
a repeated press, wrapping after `count`; otherwise 1
*/
NextWindowStep(isRepeat, lastStep, count) {
    return isRepeat ? Mod(lastStep, count) + 1 : 1
}

/** The window sizes to step through: WINDOW_STEPS, or the default if it
has problems (they are reported at startup)
*/
WindowSteps() {
    return CheckWindowSteps(WINDOW_STEPS).Length ? DEFAULT_WINDOW_STEPS : WINDOW_STEPS
}

/** Problems of the WINDOW_STEPS setting, for ReportConfig()
*/
WindowStepsProblems() {
    return CheckWindowSteps(WINDOW_STEPS)
}

/** Problems of a list of window sizes: it must be a non-empty Array of
numbers above 0 and up to 1
*/
CheckWindowSteps(steps) {
    if !(steps is Array)
        return ["is not a list such as [2/3, 1/2, 1/3]"]
    if (steps.Length = 0)
        return ["is empty"]
    problems := []
    for value in steps {
        if !(IsNumber(value) && value > 0 && value <= 1)
            problems.Push("item " A_Index ' ("' (IsObject(value) ? Type(value) : value) '") is not a number above 0 and up to 1')
    }
    return problems
}

/** Visible rectangle {x, y, w, h} of region `dir` of a work area, or "" for
other values. Up/Down/Left/Right take `fraction` of the height or width
(default 1/2), anchored to that edge, the other side full; TL/TR/BL/BR
are quarters. A region and its complement (Left 2/3 and Right 1/3, two
halves) share one split line, so they meet without a gap or an overlap,
also on an odd-sized work area. MoveWindowFrame() adds the window's
invisible borders.
*/
RegionRect(dir, waLeft, waTop, waRight, waBottom, fraction := 0.5) {
    waW := waRight - waLeft
    waH := waBottom - waTop
    ; The split line is at Round(size * part) from the left or top edge
    splitW := Round(waW / 2)
    splitH := Round(waH / 2)
    switch dir {
    case "Up":
        return {x: waLeft, y: waTop, w: waW, h: Round(waH * fraction)}
    case "Down":
        split := Round(waH * (1 - fraction))
        return {x: waLeft, y: waTop + split, w: waW, h: waH - split}
    case "Left":
        return {x: waLeft, y: waTop, w: Round(waW * fraction), h: waH}
    case "Right":
        split := Round(waW * (1 - fraction))
        return {x: waLeft + split, y: waTop, w: waW - split, h: waH}
    case "TL", "TR", "BL", "BR": ; Quarters
        right := InStr(dir, "R"), bottom := InStr(dir, "B")
        return {x: waLeft + (right ? splitW : 0), y: waTop + (bottom ? splitH : 0)
            , w: right ? waW - splitW : splitW, h: bottom ? waH - splitH : splitH}
    }
    return ""
}
