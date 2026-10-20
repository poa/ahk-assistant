;; Diagnostics

global BreakLoop := 0 ; set to 1 by Esc to stop GetWinInfo()

#HotIf ModuleOn("diag")
/** AHK
 Break loop
*/
~Esc:: {
    global BreakLoop := 1
}

;; - Multimedia Keys
Browser_Home::GetMonitorInfo()

; v1 ran a bare WinRestore after GetWinInfo(). With no "last found window"
; in a hotkey thread it did nothing (v2 would throw), so it is gone.
Browser_Favorites::GetWinInfo()

; Launch_Mail::
#HotIf

; - - -
;; Debug tool
;; - Get info
MenuHotkey("info", "diag", InfoMenu) ; Ctrl+Alt+I

InfoMenu(*) {
    HintText := "
    (
    ==Info==
    d: DPI
    i: monitors
    l: language ID
    n: locale name
    m: active monitor
    t: weekday
    w: window under mouse
    )"
    key := GetOneKey(HintText)
    switch KeyNameUS(key) {
    case "d": ; List DPI
        ListDPI()

    case "i": ; Monitor count, primary, active, geometry, DPI
        GetMonitorInfo()

    case "l": ; Show default language ID
        MsgBox DllCall("GetSystemDefaultLangID", "UShort") " - " DllCall("GetUserDefaultLangID", "UShort")

    case "n": ; User default locale name
        MsgBox GetUserDefaultLocaleName()

    case "m": ; Get active monitor number
        MsgBox GetMonitor()

    case "t": ; Current weekday
        MsgBox "The current time is " FormatTime("L1033", "ddd") "."

    case "w": ; Get windows info under mouse cursor
        GetWinInfo()
    }
}

; - - -
;; Functions

/** Live tooltip about the window under the mouse, until Esc
*/
GetWinInfo() {
    global BreakLoop := 0
    loop {
        Sleep 500
        MouseGetPos , , &whichWindow, &whichControl
        curMon := GetMonitor(whichWindow)
        MonitorGetWorkArea curMon, &waLeft, &waTop, &waRight, &waBottom

        winTitle := controls := ""
        ; 0, not "": v2 Format() throws on "" for {:d} (v1 printed 0)
        wX := wY := wW := wH := ctX := ctY := ctW := ctH := 0
        try {   ; the window may close at any moment
            winTitle := WinGetTitle(whichWindow)
            for ctrl in WinGetControls(whichWindow)
                controls .= (A_Index > 1 ? "`n" : "") ctrl
            WinGetPos &wX, &wY, &wW, &wH, whichWindow
            if (whichControl != "") {
                ; v2 gives client-area coordinates; v1 showed them relative
                ; to the window, so add the client area's offset
                ControlGetPos &ctX, &ctY, &ctW, &ctH, whichControl, whichWindow
                WinGetClientPos &clX, &clY, , , whichWindow
                ctX += clX - wX
                ctY += clY - wY
            }
        }

        text := winTitle
        text .= "`n------`n"
        text .= controls
        text .= "`n------`n"
        text .= whichControl
        text .= "`n"
        text .= Format("Win:`tx:{1: 5d},`ty:{2: 5d},`tw:{3: 5d},`th:{4: 5d}", wX, wY, wW, wH)
        text .= "`n"
        text .= Format("Ctrl:`tx:{1: 5d},`ty:{2: 5d},`tw:{3: 5d},`th:{4: 5d}", ctX, ctY, ctW, ctH)
        text .= "`n"
        text .= "Curent Monitor: " curMon
        text .= "`n"
        text .= Format("WrkAr:`tx:{1: 5d},`ty:{2: 5d},`tw:{3: 5d},`th:{4: 5d},`tR:{5: 5d},`tB:{6: 5d}"
            , waLeft, waTop, waRight - waLeft, waBottom - waTop, waRight, waBottom)
        text .= "`n"
        text .= Format("wXBordr:`t{1: 5d},`twYBordr:{2: 5d}", SysGet(5), SysGet(6))
        text .= "`n"
        text .= Format("wXFrame:`t{1: 5d},`twYFrame:{2: 5d}", SysGet(7), SysGet(8))

        ToolTip text

        if (BreakLoop = 1) {
            BreakLoop := 0
            RemoveToolTip()
            break
        }
    }
}

GetMonitorInfo() {
    monitorCount := MonitorGetCount()
    MsgBox "Monitor Count:`t" monitorCount "`nPrimary Monitor:`t" MonitorGetPrimary() "`nActive Monitor:`t" GetMonitor()
    loop monitorCount {
        name := MonitorGetName(A_Index)
        MonitorGet A_Index, &left, &top, &right, &bottom
        MonitorGetWorkArea A_Index, &waLeft, &waTop, &waRight, &waBottom
        MsgBox "Monitor:`t#" A_Index "`nName:`t" name
            . "`nLeft:`t" left " (" waLeft " work)`nTop:`t" top " (" waTop " work)"
            . "`nRight:`t" right " (" waRight " work)`nBottom:`t" bottom " (" waBottom " work)"
    }
    ListDPI()
}

ListDPI() {
    DllCall("SetThreadDpiAwarenessContext", "Ptr", -3, "Ptr") ; per-monitor aware
    hwnd := WinExist("A")
    list := ""
    for each, hMonitor in EnumMonitors() {
        dpi := GetDpiForMonitor(hMonitor)
        list .= each ". " hMonitor " " dpi.x " " dpi.y " " GetDpiForWindow(hwnd) "`n"
    }
    MsgBox list
}

/** Monitor handles, in Windows' enumeration order ([] if that fails)
*/
EnumMonitors() {
    monitors := []
    enumProc := CallbackCreate((hMonitor, *) => (monitors.Push(hMonitor), true), , 4)
    DllCall("User32\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", enumProc, "Ptr", 0, "Int")
    CallbackFree(enumProc)
    return monitors
}

GetDpiForMonitor(hMonitor, monitorDpiType := 0) { ; MDT_EFFECTIVE_DPI = 0 (shellscalingapi.h)
    dpiX := dpiY := ""
    if DllCall("Shcore\GetDpiForMonitor", "Ptr", hMonitor, "UInt", monitorDpiType, "UInt*", &x := 0, "UInt*", &y := 0, "UInt") = 0
        dpiX := x, dpiY := y
    return {x: dpiX, y: dpiY}
}

GetDpiForWindow(hwnd) {
    return DllCall("User32\GetDpiForWindow", "Ptr", hwnd, "UInt")
}

; - - -
; docs.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-getuserdefaultlocalename
; ntdef.h -> LOCALE_NAME_MAX_LENGTH = 85
GetUserDefaultLocaleName() {
    buf := Buffer(85 * 2, 0) ; UTF-16
    chars := DllCall("GetUserDefaultLocaleName", "Ptr", buf, "Int", 85, "Int")
    return StrGet(buf, chars, "UTF-16")
}
