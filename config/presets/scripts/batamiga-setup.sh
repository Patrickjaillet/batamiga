#!/bin/bash
# Batamiga first-boot setup assistant.
#
# Runs once, on the first EmulationStation "start" event of a fresh
# SHARE partition (see the "start" wrapper this is called from). Walks
# through a short sequence of steps; each is skippable; the completion
# marker is only written after the recap, so an interrupted run resumes
# from where it left off next time ES starts.
#
# Re-run any time from the Batamiga options panel ("Run setup assistant
# again"). Every real setting change re-uses the existing Batocera menus
# (language, resolution, controllers, network) via `es-setup-config` /
# `batocera-settings-set`-style calls where they exist, plus dialog(1)
# screens for the Batamiga-specific steps.
set -u
MARKER=/userdata/system/.batamiga-setup-done
STATE=/userdata/system/.batamiga-setup-state   # last completed step number
STRINGS_DIR=/usr/share/batocera/datainit/system/scripts/setup/strings
LANG_CODE="${LANG:0:2}"
[ -f "$STRINGS_DIR/$LANG_CODE.sh" ] && source "$STRINGS_DIR/$LANG_CODE.sh" \
    || source "$STRINGS_DIR/en.sh"

[ -e "$MARKER" ] && exit 0   # already completed, nothing to do

step() { echo "$1" > "$STATE"; }
last_step() { cat "$STATE" 2>/dev/null || echo 0; }

msg() { dialog --backtitle "Batamiga" --title "$1" --msgbox "$2" "${3:-12}" 64; }
yesno() { dialog --backtitle "Batamiga" --title "$1" --yesno "$2" "${3:-10}" 64; }

# --- step 1: welcome ---
if [ "$(last_step)" -lt 1 ]; then
    msg "$STR_WELCOME_TITLE" "$STR_WELCOME_BODY" 14
    step 1
fi

# --- step 2: language (reuse ES's own screen if reachable, else skip) ---
if [ "$(last_step)" -lt 2 ]; then
    yesno "$STR_LANG_TITLE" "$STR_LANG_BODY"
    [ $? -eq 0 ] && batocera-es-swissknife --lang-menu 2>/dev/null
    step 2
fi

# --- step 3: display ---
if [ "$(last_step)" -lt 3 ]; then
    yesno "$STR_DISPLAY_TITLE" "$STR_DISPLAY_BODY"
    [ $? -eq 0 ] && batocera-resolution listModes >/tmp/batamiga-modes.txt 2>/dev/null \
        && dialog --backtitle "Batamiga" --title "$STR_DISPLAY_TITLE" \
                  --textbox /tmp/batamiga-modes.txt 20 70
    step 3
fi

# --- step 4: controller ---
if [ "$(last_step)" -lt 4 ]; then
    yesno "$STR_PAD_TITLE" "$STR_PAD_BODY"
    step 4
fi

# --- step 5: network ---
if [ "$(last_step)" -lt 5 ]; then
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    msg "$STR_NET_TITLE" "$(printf "$STR_NET_BODY" "${ip:-?}")"
    step 5
fi

# --- step 6: content (games/BIOS) — offer USB import if a stick is present ---
if [ "$(last_step)" -lt 6 ]; then
    usb=$(lsblk -o MOUNTPOINT,LABEL 2>/dev/null | grep -i '/media' | head -1)
    if [ -n "$usb" ]; then
        yesno "$STR_CONTENT_TITLE" "$STR_CONTENT_USB_BODY"
        [ $? -eq 0 ] && /userdata/system/scripts/batamiga-import.sh --interactive
    else
        msg "$STR_CONTENT_TITLE" "$STR_CONTENT_NOUSB_BODY" 14
    fi
    step 6
fi

# --- step 7: Kickstart / AROS ---
if [ "$(last_step)" -lt 7 ]; then
    msg "$STR_AROS_TITLE" "$STR_AROS_BODY" 14
    step 7
fi

# --- step 8: usage profile ---
if [ "$(last_step)" -lt 8 ]; then
    dialog --backtitle "Batamiga" --title "$STR_PROFILE_TITLE" \
        --menu "$STR_PROFILE_BODY" 16 64 4 \
        living "$STR_PROFILE_LIVING" \
        desk   "$STR_PROFILE_DESK" \
        kiosk  "$STR_PROFILE_KIOSK" \
        kid    "$STR_PROFILE_KID" \
        2>/tmp/batamiga-profile.txt
    if [ -s /tmp/batamiga-profile.txt ]; then
        /userdata/system/scripts/apply-profile.sh "$(cat /tmp/batamiga-profile.txt)"
    fi
    step 8
fi

# --- step 9: recap, mark done ---
msg "$STR_DONE_TITLE" "$STR_DONE_BODY" 12
mkdir -p "$(dirname "$MARKER")"
date -Iseconds > "$MARKER"
rm -f "$STATE"
