#Requires AutoHotkey v2.0
#Warn All, StdOut
; Checks the window sizes of Ctrl+Win+arrows and the numpad: RegionRect()
; with fractions, the step cycle (NextWindowStep()) and the WINDOW_STEPS
; check. Prints failures and a summary, exits with the number of failures
; (0 = OK). It moves no window.
;   AutoHotkey64.exe /ErrorStdOut tests\window.ahk

DEBUG := false
DELAY := 50
HINTS := false
DEFAULT_MENU_KEYS := Map(), MENU_KEYS := Map()
DEFAULT_MODULES := Map("window", true), MODULES := DEFAULT_MODULES.Clone()
WINDOW_STEPS := [2/3, 1/2, 1/3]
DEFAULT_WINDOW_STEPS := WINDOW_STEPS.Clone()
#Include %A_ScriptDir%\..\lib\tools.ahk
#Include %A_ScriptDir%\..\lib\window.ahk

checks := 0
failures := 0

Check(name, got, want) {
    global checks, failures
    checks++
    if (got != want) {
        failures++
        FileAppend "FAIL " name ": got [" got "], want [" want "]`n", "*"
    }
}

/** "x y w h" of RegionRect() on a work area, "" for an unknown region
*/
RectText(dir, wa, fraction := 0.5) {
    r := RegionRect(dir, wa[1], wa[2], wa[3], wa[4], fraction)
    return r ? r.x " " r.y " " r.w " " r.h : ""
}

/** True if region `first` ends exactly where `second` starts (no gap, no
overlap): along x for "x", along y for "y"
*/
Meets(first, second, axis) {
    return axis = "x" ? first.x + first.w = second.x : first.y + first.h = second.y
}

; A 1920x1040 work area at 0,0 (taskbar below): exact visible rectangles
wa := [0, 0, 1920, 1040]
Check("left 2/3", RectText("Left", wa, 2/3), "0 0 1280 1040")
Check("left 1/2", RectText("Left", wa, 1/2), "0 0 960 1040")
Check("left 1/3", RectText("Left", wa, 1/3), "0 0 640 1040")
Check("right 2/3", RectText("Right", wa, 2/3), "640 0 1280 1040")
Check("right 1/2", RectText("Right", wa, 1/2), "960 0 960 1040")
Check("right 1/3", RectText("Right", wa, 1/3), "1280 0 640 1040")
Check("up 2/3", RectText("Up", wa, 2/3), "0 0 1920 693")
Check("up 1/2", RectText("Up", wa, 1/2), "0 0 1920 520")
Check("up 1/3", RectText("Up", wa, 1/3), "0 0 1920 347")
Check("down 2/3", RectText("Down", wa, 2/3), "0 347 1920 693")
Check("down 1/2", RectText("Down", wa, 1/2), "0 520 1920 520")
Check("down 1/3", RectText("Down", wa, 1/3), "0 693 1920 347")
Check("default fraction is a half", RectText("Left", wa), RectText("Left", wa, 1/2))
Check("quarter TL", RectText("TL", wa), "0 0 960 520")
Check("quarter BR", RectText("BR", wa), "960 520 960 520")
Check("quarter ignores fraction", RectText("BR", wa, 2/3), "960 520 960 520")
Check("unknown region", RectText("Max", wa), "")

; A second monitor right of the first and higher, with an odd size
wa := [1920, -200, 3201, 825] ; 1281 x 1025
Check("odd left 2/3", RectText("Left", wa, 2/3), "1920 -200 854 1025")
Check("odd right 1/2", RectText("Right", wa, 1/2), "2561 -200 640 1025")
Check("odd down 1/3", RectText("Down", wa, 1/3), "1920 483 1281 342")
Check("odd quarter TR", RectText("TR", wa), "2561 -200 640 513")
Check("odd quarter BL", RectText("BL", wa), "1920 313 641 512")

; Complements meet exactly: no gap, no overlap, also on the odd monitor
CheckMeets(a) {
    Part(dir, fraction := 0.5) => RegionRect(dir, a[1], a[2], a[3], a[4], fraction)
    label := " on " a[3] - a[1] "x" a[4] - a[2]
    Check("halves meet" label, Meets(Part("Left"), Part("Right"), "x"), true)
    Check("left 2/3 meets right 1/3" label, Meets(Part("Left", 2/3), Part("Right", 1/3), "x"), true)
    Check("left 1/3 meets right 2/3" label, Meets(Part("Left", 1/3), Part("Right", 2/3), "x"), true)
    Check("up 1/3 meets down 2/3" label, Meets(Part("Up", 1/3), Part("Down", 2/3), "y"), true)
    Check("up 2/3 meets down 1/3" label, Meets(Part("Up", 2/3), Part("Down", 1/3), "y"), true)
    Check("quarters meet across" label, Meets(Part("TL"), Part("TR"), "x"), true)
    Check("quarters meet down" label, Meets(Part("TL"), Part("BL"), "y"), true)
    Check("right edge at work area" label, Part("Right", 1/3).x + Part("Right", 1/3).w, a[3])
    Check("bottom edge at work area" label, Part("Down", 1/3).y + Part("Down", 1/3).h, a[4])
}
CheckMeets([0, 0, 1920, 1040])
CheckMeets([1920, -200, 3201, 825])

; The step cycle: first press 1, repeats 2, 3, then back to 1
Check("step first press", NextWindowStep(false, 0, 3), 1)
Check("step second", NextWindowStep(true, 1, 3), 2)
Check("step third", NextWindowStep(true, 2, 3), 3)
Check("step wraps", NextWindowStep(true, 3, 3), 1)
Check("step not a repeat resets", NextWindowStep(false, 2, 3), 1)
Check("step after a shorter list", NextWindowStep(true, 5, 3), 3)

; WINDOW_STEPS check
ProblemsText(steps) {
    text := ""
    for problem in CheckWindowSteps(steps)
        text .= (text = "" ? "" : " | ") problem
    return text
}
Check("steps valid", ProblemsText([2/3, 1/2, 1/3]), "")
Check("steps valid one", ProblemsText([1]), "")
Check("steps not a list", ProblemsText("2/3"), "is not a list such as [2/3, 1/2, 1/3]")
Check("steps empty", ProblemsText([]), "is empty")
Check("steps zero and too big", ProblemsText([0, 1/2, 1.5]), 'item 1 ("0") is not a number above 0 and up to 1 | item 3 ("1.5") is not a number above 0 and up to 1')
Check("steps text", ProblemsText(["half"]), 'item 1 ("half") is not a number above 0 and up to 1')
Check("steps object", ProblemsText([Map()]), 'item 1 ("Map") is not a number above 0 and up to 1')
WINDOW_STEPS := []
Check("steps bad setting uses default", WindowSteps().Length, 3)
Check("steps bad setting is reported", WindowStepsProblems().Length, 1)

FileAppend checks " checks, " failures " failed`n", "*"
ExitApp failures
