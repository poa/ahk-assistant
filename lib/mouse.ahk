;; change mouse speed
; Precision mode (a slower mouse). The hotkeys come from MOUSE_KEYS
; (config.default.ahk), the speed from MOUSE_SLOW_SPEED:
; "hold" (XButton1): precision mode while the key is held.
; "toggle" (Ctrl+Alt+M): toggle precision mode.

; - - -
;; Hotkeys
SettingHotkey("MOUSE_KEYS", MOUSE_KEYS, DEFAULT_MOUSE_KEYS, "hold", "mouse", SlowMouseTemporary)
SettingHotkey("MOUSE_KEYS", MOUSE_KEYS, DEFAULT_MOUSE_KEYS, "toggle", "mouse", (*) => SlowMouseToggle())

; - - -
;; Functions

; Runs at startup (v2 runs top-level code in included files)
global MouseCfg := {
    NormalSpeed: GetMouseSpeed(),   ; the user's own setting (1-20)
    SlowSpeed: MouseSlowSpeed()
}
MouseCfg.NormalSpeedMsg := Chr(0x26A1) "Normal mode: speed=" MouseCfg.NormalSpeed  ; Lightning
MouseCfg.SlowSpeedMsg := Chr(0x1F422) "Precision mode: speed=" MouseCfg.SlowSpeed ; Turtle
MouseCfg.CurrentSpeed := MouseCfg.NormalSpeed
OnExit(MouseExit)

/** MOUSE_SLOW_SPEED, or the default if it isn't a whole number from 1 to 20
(noted for ReportConfig())
*/
MouseSlowSpeed() {
    if (IsInteger(MOUSE_SLOW_SPEED) && MOUSE_SLOW_SPEED >= 1 && MOUSE_SLOW_SPEED <= 20)
        return Integer(MOUSE_SLOW_SPEED)
    value := IsObject(MOUSE_SLOW_SPEED) ? Type(MOUSE_SLOW_SPEED) : MOUSE_SLOW_SPEED
    ComboKeys.Problems.Push('MOUSE_SLOW_SPEED: "' value '" is not a whole number from 1 to 20')
    return DEFAULT_MOUSE_SLOW_SPEED
}

; Don't leave the mouse slow after Exit or Reload
MouseExit(*) {
    if (GetMouseSpeed() = MouseCfg.SlowSpeed)
        SetMouseSpeed(MouseCfg.NormalSpeed)
}

; Slowdown mouse while the hotkey's key ("XButton1", "sc031") is held
SlowMouseTemporary(thisHotkey) {
    ShowToolTip(MouseCfg.SlowSpeedMsg)
    SetMouseSpeed(MouseCfg.SlowSpeed)
    KeyWait RegExReplace(thisHotkey, "^[\^!+#]+")
    ; Back to the toggled speed, which is normal unless toggled to slow
    SetMouseSpeed(MouseCfg.CurrentSpeed)
    if (MouseCfg.CurrentSpeed = MouseCfg.NormalSpeed)
        ShowToolTip(MouseCfg.NormalSpeedMsg)
}

; Toggle mouse speed
SlowMouseToggle() {
    if (MouseCfg.CurrentSpeed = MouseCfg.NormalSpeed) {
        MouseCfg.CurrentSpeed := MouseCfg.SlowSpeed
        ShowToolTip(MouseCfg.SlowSpeedMsg)
    } else {
        MouseCfg.CurrentSpeed := MouseCfg.NormalSpeed
        ShowToolTip(MouseCfg.NormalSpeedMsg)
    }
    SetMouseSpeed(MouseCfg.CurrentSpeed)
}

GetMouseSpeed() {
    DllCall("SystemParametersInfo", "UInt", 0x70, "UInt", 0, "UInt*", &speed := 0, "UInt", 0) ; SPI_GETMOUSESPEED
    return speed
}

SetMouseSpeed(speed) {
    ; The speed itself goes in pvParam, a pointer-sized argument
    DllCall("SystemParametersInfo", "UInt", 0x71, "UInt", 0, "Ptr", speed, "UInt", 0) ; SPI_SETMOUSESPEED
}
