; - - -
;; Markup snippets
; Markdown, Jira or Confluence markup, picked by GetMarkupTarget().
; Clipboard work goes through CopySelection / PasteText / RestoreClipboard,
; which keep non-text clipboard contents. A key that isn't in a menu does
; nothing and restores the clipboard.

global __LinkTitle := "" ; set by Alt+Shift+L, n

;; - Link hotkeys
/** Issue key (KEY-123) of a URL of a tracker in TRACKERS (Assistant.ahk);
"" if the URL fits none of them
*/
TrackerIssueId(url) {
    for name, tracker in TRACKERS {
        if RegExMatch(url, "https?://" tracker["host"] tracker["path"] "(?<id>[a-zA-Z0-9]+-\d+)", &m)
            return m.id
    }
    return ""
}

/** Link to `url` titled `title`, in the active window's markup:
[title|url] in Jira, Markdown [title](url) elsewhere (Confluence too, for now)
`target` (default: the active window's) can be set by tests
*/
MakeLink(title, url, target := GetMarkupTarget()) {
    if (target = "jira")
        return "[" title "|" url "]"
    return "[" title "](" url ")"
}
/**
Alt+Shift+L, then:
n:  Save selected as Link Title
k:  If Link Title is saved before, make link as [LinkTitle](Clipboard)
l:  If some Text is Selected, make link as [Selected](Clipboard)
        otherwise, make link as [](Clipboard) and place cursor between brackets
t:  If Clipboard matches a tracker link (TRACKERS) make link as [KEY-123](Link)
        otherwise, make link as [](Clipboard) and place cursor between brackets
r:  RFC link (same fallback as t)
*/
MenuHotkey("link", "markup", (*) => GuardClipboard(LinkMenu)) ; Alt+Shift+L

LinkMenu() {
    global __LinkTitle
    HintText := "
    (
    ==Link==
    l: [Selected](Clipboard) wrap selection as a title
    n: save selection as a LinkTitle for later use
    k: [LinkTitle](Clipboard) link with saved title
    r: [RFC-Number](Clipboard) link with RFC number
    t: [TrackerTask](Clipboard) link with tracker task
    1: [experimental] app menu
    )"
    keyName := KeyNameUS(GetOneKey(HintText))
    if (!RegExMatch(keyName, "^[lnkrt1]$"))
        return ; Not a menu key: nothing copied, nothing sent
    SetKeyDelay 100
    ; Only l and n use the selection, so only they press Ctrl+C: in a
    ; terminal, Ctrl+C with nothing selected interrupts the program
    if (keyName = "l" || keyName = "n") {
        ; Short wait, like v1: the menu key must not reach the app
        selected := CopySelection(&saved, &url, DELAY / 1000) ; url: the clipboard text
    } else {
        selected := ""
        SaveClipboard(&saved, &url)
    }
    len := 0
    link := ""
    if (DEBUG)
        ToolTip A_Hour ":" A_Min ":" A_Sec "`nURL: " url "`nSelected: " selected "`nLink: " link "`nCount: " len

    switch keyName {
    case "t":
        if (issueId := TrackerIssueId(url)) {
            link := MakeLink(issueId, url)
        } else {
            link := MakeLink("", url)
            len := StrLen(link) - 1
        }
        Sleep DELAY

    case "k":
        link := MakeLink(__LinkTitle, url)
        Sleep DELAY
        if (StrLen(__LinkTitle) == 0)
            len := StrLen(link) - 1

    case "l":
        if (selected = "") {
            link := MakeLink("", url)
            len := StrLen(link) - 1
        } else {
            link := MakeLink(selected, url)
        }
        Sleep DELAY

    case "n": ; Save selection as the link title
        __LinkTitle := selected
        RestoreClipboard(saved)
        return

    case "r":
        if RegExMatch(url, "https?://.*/rfc\d{3,4}") {
            ;https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.4
            ;https://www.rfc-editor.org/rfc/rfc9110#name-field-names
            link := MakeLink(RegExReplace(url, "(https?://.*/)(rfc\d{3,4})(#.*)?", "$2$3"), url)
        } else {
            link := MakeLink("", url)
            len := StrLen(link) - 1
        }

    case "1": ; Experimental, app-specific: URL from the app's Alt+Shift+R menu
        title := url
        Sleep DELAY
        Send "!+r"
        Sleep DELAY
        Send "{Down}"
        Sleep DELAY
        Send "^{Ins}"
        Sleep DELAY
        Send "{Esc}"
        link := MakeLink(title, A_Clipboard)
        Sleep DELAY
    }
    if (DEBUG)
        ToolTip A_Hour ":" A_Min ":" A_Sec "`nURL: " url "`nSelected: " selected "`nLink: " link "`nCount: " len
    Sleep DELAY
    PasteText(link)
    Send "{Left " len "}"
    RestoreClipboard(saved)
}

;; - Single backtick for inline code
MenuHotkey("code", "markup", (*) => GuardClipboard(InlineCodeMenu)) ; Alt+`

InlineCodeMenu() {
    ; Markdown: `…`; Jira and Confluence: {{…}}
    if (GetMarkupTarget() = "markdown")
        markBegin := markEnd := "``"
    else
        markBegin := "{{", markEnd := "}}"
    HintText := "
    (
    ==Code==
    ``: selection
    v: clipboard
    )"
    keyName := KeyNameUS(GetOneKey(HintText))
    if (keyName != "v" && keyName != "``")
        return ; Not a menu key: nothing copied, nothing sent
    SetKeyDelay 100
    counter := 0

    if (keyName = "v") { ; Paste from Clipboard as inline code
        SaveClipboard(&saved, &clipText) ; No Ctrl+C: it interrupts in a terminal
        text := markBegin clipText
    } else {
        selected := CopySelection(&saved, &clipText)
        if (selected = "") {
            text := markBegin
            counter := StrLen(markEnd)
        } else {
            text := markBegin selected
        }
    }
    PasteText(text)
    Sleep DELAY
    SendText markEnd
    Sleep DELAY
    Send "{Left " counter "}"
    Sleep DELAY
    RestoreClipboard(saved)
}

;; - Triple backtick for multiline code
MenuHotkey("codeblock", "markup", (*) => GuardClipboard(CodeBlockMenu)) ; Ctrl+Shift+`

CodeBlockMenu() {
    HintText := "
    (
    ==Code block==
    ``: selection
    v: clipboard
    )"
    key := GetOneKey(HintText)
    keyName := KeyNameUS(key)
    if (keyName != "v" && keyName != "``")
        return ; Not a menu key: nothing copied, nothing sent
    SetKeyDelay 100
    if (keyName = "v") {
        selected := ""
        SaveClipboard(&saved, &clipText) ; No Ctrl+C: it interrupts in a terminal
    } else {
        ; Short wait, like v1
        selected := CopySelection(&saved, &clipText, DELAY / 1000)
    }
    counter := 0
    Sleep DELAY

    switch GetMarkupTarget() {
    case "confluence":
        ; Its editor turns typed ``` into a code block with the caret inside
        ; (a typed {code} stays plain text), so there is no end marker
        if (keyName = "v") {
            text := clipText
        } else if (selected = "") {
            text := ""
        } else {
            text := selected
            Send "{Del}"
            Sleep DELAY
        }
        SendText "``````"
        Sleep 300
        PasteText(text)

    case "jira":
        if (keyName = "v") {
            text := clipText
        } else if (selected = "") {
            text := ""
            counter := 2
        } else {
            text := selected
            Send "{Del}"
            Sleep DELAY
        }
        SendText "{code}"
        Send "+{Enter}"
        Sleep DELAY
        PasteText(text)
        Send "+{Enter}"
        SendText "{code}"
        Send "+{Enter}"
        Sleep DELAY

    default: ; Markdown
        fenceBegin := "```````n"
        fenceEnd := "`n```````n"
        if (keyName = "v") {
            text := fenceBegin clipText fenceEnd
        } else if (selected = "") {
            text := fenceBegin fenceEnd
            counter := 2
        } else {
            text := fenceBegin selected fenceEnd
            Send "{Del}"
            Sleep DELAY
        }
        PasteText(text)
        Sleep DELAY
    }

    Send "{Up " counter "}"
    Sleep DELAY
    RestoreClipboard(saved)
}
