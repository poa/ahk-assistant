;; change mouse speed
; Ctrl+Alt+LShift (hold): precision mode while LShift is down.
; RCtrl+RAlt: toggle precision mode.

; - - -
;; Hotkeys
#HotIf ModuleOn("mouse")
;; - slow mouse while key is pressed
~^!LShift::SlowMouseTemporary()

;; - toggle slow mouse mode
>^RAlt::SlowMouseToggle() ; RAlt while RCtrl is held
#HotIf

; - - -
;; Functions

; Runs at startup (v2 runs top-level code in included files)
global MouseCfg := {
    TemporaryKey: "LShift",         ; must match the ~^!LShift hotkey below
    NormalSpeed: GetMouseSpeed(),   ; the user's own setting (1-20)
    SlowSpeed: 2
}
MouseCfg.NormalSpeedMsg := Chr(0x26A1) "Normal mode: speed=" MouseCfg.NormalSpeed  ; Lightning
MouseCfg.SlowSpeedMsg := Chr(0x1F422) "Precision mode: speed=" MouseCfg.SlowSpeed ; Turtle
MouseCfg.CurrentSpeed := MouseCfg.NormalSpeed
OnExit(MouseExit)

; Don't leave the mouse slow after Exit or Reload
MouseExit(*) {
    if (GetMouseSpeed() = MouseCfg.SlowSpeed)
        SetMouseSpeed(MouseCfg.NormalSpeed)
}

; Slowdown mouse for a while
SlowMouseTemporary() {
    ShowToolTip(MouseCfg.SlowSpeedMsg)
    SetMouseSpeed(MouseCfg.SlowSpeed)
    KeyWait MouseCfg.TemporaryKey
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
