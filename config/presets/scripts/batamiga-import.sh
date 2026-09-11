#!/bin/bash
# Batamiga — import Amiga content from a mounted USB drive.
#
#   batamiga-import.sh --interactive
#
# Scans mounted removable media for Amiga ROM/disk files and known
# Kickstart filenames, and copies them into place. Never downloads
# anything and never ships a Kickstart itself — everything it copies
# comes from a drive the user plugged in. Kickstart detection is by
# filename + a table of expected SHA1 hashes shipped in
# config/kickstart-hashes.txt (hashes only, never ROM bytes), purely to
# tell the user "this looks like a genuine Kickstart 1.3" — it is not a
# protection check and does not gate anything.
#
# Stub for Phase 16 (game DB / .m3u generation) and full Phase 25
# (dedupe, backup-from-UI). Already handles the two simplest and most
# useful cases: copy known Amiga file extensions to the right roms/
# folder by system, and offer to copy a recognized Kickstart.
set -u

ROM_EXT_AMIGA='adf|adz|dms|dmz|ipf|hdf|lha|uae|scp|raw'
ROM_EXT_CD32='iso|cue|chd|nrg'
HASHES=/usr/share/batocera/datainit/system/scripts/kickstart-hashes.txt

mounts() {
    lsblk -o MOUNTPOINT -nr 2>/dev/null | grep -E '^/(media|run/media)'
}

import_games() {
    local mnt="$1"
    find "$mnt" -type f -regextype posix-extended -iregex ".*\.(${ROM_EXT_AMIGA})" 2>/dev/null | while read -r f; do
        # naive system guess: AGA-tagged or explicit amiga1200 folder -> amiga1200, else amiga500
        case "$f" in
            *[Aa][Gg][Aa]*|*[Aa]1200*) dest=amiga1200 ;;
            *) dest=amiga500 ;;
        esac
        mkdir -p "/userdata/roms/$dest"
        cp -n "$f" "/userdata/roms/$dest/"
        echo "imported: $(basename "$f") -> roms/$dest/"
    done
    find "$mnt" -type f -regextype posix-extended -iregex ".*\.(${ROM_EXT_CD32})" 2>/dev/null | while read -r f; do
        mkdir -p /userdata/roms/amigacd32
        cp -n "$f" /userdata/roms/amigacd32/
        echo "imported: $(basename "$f") -> roms/amigacd32/"
    done
}

import_kickstarts() {
    local mnt="$1"
    [ -f "$HASHES" ] || return 0
    find "$mnt" -maxdepth 4 -type f 2>/dev/null | while read -r f; do
        sum=$(sha1sum "$f" 2>/dev/null | cut -d' ' -f1)
        name=$(grep -i "^$sum " "$HASHES" | cut -d' ' -f2-)
        if [ -n "$name" ]; then
            mkdir -p /userdata/bios/amiga
            cp -n "$f" "/userdata/bios/amiga/$name"
            echo "kickstart recognized: $name (from $(basename "$f"))"
        fi
    done
}

main() {
    local found=0
    for m in $(mounts); do
        found=1
        import_games "$m"
        import_kickstarts "$m"
    done
    [ "$found" = 0 ] && { echo "batamiga-import: no removable media mounted"; return 1; }
    /usr/bin/emulationstation --update-gamelists 2>/dev/null || true
    return 0
}

main "$@"
