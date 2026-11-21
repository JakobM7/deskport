#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
cd "$repo"

in_terminal=false
if [[ ${1:-} == --in-terminal ]]; then
    in_terminal=true
    shift
fi
rebuild=false
if [[ ${1:-} == --build ]]; then
    rebuild=true
    shift
fi
if [[ $in_terminal == true ]]; then
    trap 'code=$?; if (( code )); then read -r -p "Press Enter to close..." || true; fi' EXIT
fi

local_launcher="$repo/build/deskport"
local_builder="$repo/build/rebuild-deskport"
if [[ $rebuild == false && -x $local_launcher ]]; then
    exec "$local_launcher" "$@"
fi

checkout_build=$(bash scripts/build-paths.sh checkout)
cached_run="$checkout_build/source-launch/linux-run"
if [[ $rebuild == false && -s $cached_run ]] &&
    IFS= read -r executable < "$cached_run" &&
    [[ $executable == /nix/store/*/bin/deskport && -x $executable ]]; then
    exec "$executable" "$@"
fi

# A file-manager launch needs a terminal for build progress and errors.
if [[ $in_terminal == false && ! -t 0 && ( -n ${DISPLAY:-} || -n ${WAYLAND_DISPLAY:-} ) ]]; then
    launch=(bash "$repo/Start-DeskPort.sh" --in-terminal --build "$@")
    for terminal in konsole gnome-terminal kgx x-terminal-emulator xterm; do
        if command -v "$terminal" >/dev/null; then
            case "$terminal" in
                gnome-terminal|kgx) exec "$terminal" -- "${launch[@]}" ;;
                *) exec "$terminal" -e "${launch[@]}" ;;
            esac
        fi
    done
fi

if [[ -x $local_builder && -x $local_launcher ]]; then
    "$local_builder"
    "$local_launcher" "$@"
    exit
fi

if ! command -v nix >/dev/null; then
    printf '%s\n' 'Building DeskPort on Linux requires Nix with flakes enabled.' >&2
    exit 1
fi

git submodule update --init --recursive
run="source-$(date -u +%Y%m%dT%H%M%S)-$$"
bash scripts/build.sh build --target linux-nix --run "$run"
IFS= read -r output < "$checkout_build/records/$run/linux-nix/nix-outputs.txt"
executable="$output/bin/deskport"
if [[ $output != /nix/store/* || ! -x $executable ]]; then
    printf '%s\n' 'The build did not produce a runnable DeskPort executable.' >&2
    exit 1
fi
mkdir -p "$(dirname -- "$cached_run")"
printf '%s\n' "$executable" > "$cached_run"
"$executable" "$@"
