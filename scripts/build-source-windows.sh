#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$repo"

if [[ $(uname -m) != x86_64 ]] || ! command -v nix-shell >/dev/null; then
    printf '%s\n' 'Install Nix inside an x64 WSL distribution and make nix-shell available in its login shell.' >&2
    exit 1
fi
: "${DESKPORT_WINDOWS_LAUNCH_ROOT:?Start this build from Start-DeskPort.cmd}"

git submodule update --init --recursive
run="source-$(date -u +%Y%m%dT%H%M%S)-$$"
bash scripts/build.sh package --target windows --run "$run"
checkout_build=$(bash scripts/build-paths.sh checkout)
checkout_id=${checkout_build##*/}
dist=$(DESKPORT_RUN_ID="$run" DESKPORT_TARGET=windows bash scripts/build-paths.sh dist)
shopt -s nullglob
archives=("$dist"/DeskPort-*-windows-x64-portable*.zip)
if (( ${#archives[@]} != 1 )); then
    printf '%s\n' 'Expected exactly one Windows portable ZIP from the build.' >&2
    exit 1
fi

# Copy the audited source build to a Windows filesystem for native startup.
destination="$DESKPORT_WINDOWS_LAUNCH_ROOT/$checkout_id/$run"
mkdir -p "${destination%/*}" "$repo/build"
mkdir "$destination"
python3 -m zipfile -e "${archives[0]}" "$destination"
if [[ ! -f $destination/DeskPort.exe ]]; then
    printf '%s\n' 'DeskPort.exe is missing from the portable ZIP.' >&2
    exit 1
fi
rm -f -- "$destination/portable.dat"

# Only the relative ASCII path is passed back through cmd.exe.
pointer=$(mktemp "$repo/build/.windows-source.XXXXXX")
trap 'rm -f -- "$pointer"' EXIT
printf '%s\\%s\\DeskPort.exe\r\n' "$checkout_id" "$run" > "$pointer"
mv -f -- "$pointer" "$repo/build/windows-source.path"
