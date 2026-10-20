;; Date and time snippets

;; - TimeStamps
; Alt+Shift+T (MENU_KEYS "datetime"), then a key. The hint shows the very
; strings the keys type, all made from the time the menu opened. L1033
; (en-US) keeps weekday names in English.
MenuHotkey("datetime", "datetime", DateTimeMenu)

DateTimeMenu(thisHotkey) {
    now := A_Now " L1033"
    stamps := Map( ; Key -> text; the hint lists them in key order
        "a", FormatTime(now, "yyyy-MM-dd HH-mm-ss"), ; date + time
        "d", FormatTime(now, "yyyy-MM-dd"),          ; date only
        "s", FormatTime(now, "yyyy-MM-ddTHH:mm:ss"), ; date + time, ISO
        "t", FormatTime(now, "HH:mm:ss"),            ; time only
        "w", FormatTime(now, "yyyy-MM-dd.ddd")       ; date + weekday
    )
    HintText := "==Date and time=="
    for key, stamp in stamps
        HintText .= "`n" key ": " stamp

    key := KeyNameUS(GetOneKey(HintText))
    if (stamps.Has(key)) {
        SendText stamps[key]
    } else { ; Not ours: pass the menu combo on to the active app
        PassMenuCombo(thisHotkey)
    }
}
