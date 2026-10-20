;; Emoji snippets
; Alt+Shift+E (MENU_KEYS "emoji"), then a key. The key is read as a scan
; code, so the menu works in any layout. Cases are the key's US name; "+"
; before it means Shift is held ("+v" is Shift+V).

MenuHotkey("emoji", "emoji", EmojiMenu)

EmojiMenu(*) {
    HintText := "
    (
    ==Emoji==
    1: ❗    | +1: ‼️    | 2: ✔️ OK | 3: ❌ NOK
    v: ✔️    | +v: ✔     | x: ❌    | +x: ✗
    6,w: ⚠️  | 7,+/: ❓  | 8: *️⃣
    -: ➖    | +=: ➕    | +4: 💲
    i: ℹ️    | a: ->     | o: 🆗    | n: ⛔  | s: 🛑  | t: 🤷
    )"
    key := GetOneKey(HintText, &shift)
    switch (shift ? "+" : "") KeyNameUS(key) {
    case "1": ; exclamation
        SendText "❗"

    case "+1": ; red exclamation
        SendText "‼️"

    case "2": ; ✔️ OK
        Send "{U+2714}{U+FE0F} OK"

    case "v": ; Checkmark (heavy, colored)
        SendText "✔️"

    case "+v": ; Checkmark (light, monocolor)
        SendText "✔"

    case "3": ; Crossmark + NOK (❌ NOK)
        SendText "❌ NOK"

    case "t": ; Shrug
        Send "{U+1F937}"

    case "x": ; Crossmark (colored)
        Send "{U+274C}"

    case "+x": ; Crossmark (monocolor)
        SendText "✗"

    case "+4", ";": ; dollar sign
        SendText "💲"

    case "6", "+6", "w": ; Warning sign
        SendText "⚠️"

    case "7", "+7", "+/": ; red question
        SendText "❓"

    case "8", "+8", "NumpadMult": ; Keycap *
        SendText "*️⃣"

    case "-", "NumpadSub": ; :heavy_minus_sign:
        SendText "➖"

    case "+=", "NumpadAdd": ; :heavy_plus_sign:
        SendText "➕"

    case "i": ; Info
        Send "{U+2139}{U+FE0F}"

    case "a": ; ->
        SendText "->"

    case "o": ; Ok
        SendText "🆗"

    case "n": ; No entry
        SendText "⛔"

    case "s": ; Stop
        SendText "🛑"
    }
}
