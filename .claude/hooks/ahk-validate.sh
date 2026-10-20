#!/usr/bin/env bash
# Claude Code PostToolUse hook (Edit, Write, MultiEdit, Bash): run
# AutoHotkey v2's /validate on the v2 scripts whose files have changed.
#
# - Assistant.ahk is checked together with everything it includes, so a
#   change in Assistant.ahk, lib/ or config*.ahk triggers it. Other scripts
#   that start with "#Requires AutoHotkey v2" in the root are checked on
#   their own.
# - Changes are found by a checksum of the files, not by parsing the tool
#   call, so edits made from Bash count too.
# - Errors and "Warning:" lines go to stderr with exit 2, which Claude
#   Code feeds back to Claude. Each state of the files is reported once
#   per session; the next change is checked again.
# - /validate only loads the script; nothing runs.
#
# AutoHotkey path: AHK_V2_EXE, else the default install (WSL or Git Bash).

set -u

# Git Bash (MSYS) and Cygwin turn arguments that look like paths into
# Windows paths, so "/validate" would reach AutoHotkey as
# "C:/Program Files/Git/validate" and fail with no message. WSL doesn't.
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        export MSYS_NO_PATHCONV=1 # Git for Windows
        export MSYS2_ARG_CONV_EXCL='*' # MSYS2
        ;;
esac

input=$(cat)
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0
shopt -s nullglob nocaseglob

session=$(printf '%s' "$input" | grep -o '"session_id" *: *"[^"]*"' | head -n 1 | sed 's/.*"\([^"]*\)"$/\1/')
state_dir="${TMPDIR:-/tmp}/ahk-validate/$(pwd | md5sum | cut -c1-8)/${session:-nosession}"
mkdir -p "$state_dir" || exit 0

exe="${AHK_V2_EXE:-}"
if [[ -z "$exe" ]]; then
    for candidate in "/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe" \
                     "/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe"; do
        if [[ -f "$candidate" ]]; then
            exe="$candidate"
            break
        fi
    done
fi
if [[ -z "$exe" || ! -f "$exe" ]]; then
    # Tell the user once per session that edits aren't checked
    if [[ ! -e "$state_dir/no-exe" ]]; then
        touch "$state_dir/no-exe"
        echo "ahk-validate: AutoHotkey v2 not found, so edits are not validated. Set AHK_V2_EXE." >&2
        exit 1 # non-blocking: shown to the user only
    fi
    exit 0
fi

# Scripts to check
targets=()
[[ -f Assistant.ahk ]] && targets+=(Assistant.ahk)
for f in *.ahk; do
    [[ "$f" == Assistant.ahk ]] && continue
    head -n 5 "$f" | sed '1s/^\xEF\xBB\xBF//' | grep -qi '^#Requires AutoHotkey v2' && targets+=("$f")
done

report=""
for target in "${targets[@]}"; do
    if [[ "$target" == Assistant.ahk ]]; then
        files=(Assistant.ahk lib/*.ahk config*.ahk)
    else
        files=("$target")
    fi
    sum=$(md5sum -- "${files[@]}" | md5sum | cut -c1-32)
    stamp="$state_dir/$(printf '%s' "$target" | md5sum | cut -c1-8)"
    [[ -f "$stamp" && "$(cat "$stamp")" == "$sum" ]] && continue
    printf '%s\n' "$sum" > "$stamp"

    out=$(set -o pipefail; timeout 30 "$exe" /ErrorStdOut /validate "$target" 2>&1 | tr -d '\r')
    rc=$?
    if [[ $rc -ne 0 || -n "$out" ]]; then
        [[ $rc -eq 124 ]] && out="${out:+$out$'\n'}(timed out after 30 s: a dialog may be open)"
        report+="AutoHotkey /validate $target (exit $rc):"$'\n'"$out"$'\n\n'
    fi
done

if [[ -n "$report" ]]; then
    {
        printf '%s' "$report"
        echo "Fix these before going on (see \"Checking changes\" in AGENTS.md)."
    } >&2
    exit 2
fi
exit 0
