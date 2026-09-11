#!/bin/bash
# Batamiga options panel.
#
# A text menu (dialog(1)) over the settings this project adds on top of
# stock Batocera: ambiance profile, theme variant, per-game
# auto-configuration, network, rotation, kiosk mode. Reads and writes
# /userdata/system/batocera.conf directly — the same file ES itself
# reads, so a change here takes effect on the next relaunch/reboot like
# any other Batocera setting.
#
# Launched as a "game" of the batocera-provided `ports` system (see
# config/presets/roms/ports/Batamiga Settings.sh in the datainit tree),
# so it appears as an entry in EmulationStation without any custom UI
# code. Requires `dialog` (already part of Batocera).
set -u
CONF=/userdata/system/batocera.conf
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

get() { grep -m1 "^$1=" "$CONF" 2>/dev/null | cut -d= -f2-; }

set_kv() {
    local key="$1" val="$2"
    if grep -q "^$key=" "$CONF" 2>/dev/null; then
        sed -i "s#^$key=.*#$key=$val#" "$CONF"
    else
        echo "$key=$val" >> "$CONF"
    fi
}

ambiance_menu() {
    local cur
    cur="$(get batamiga.ambiance)"
    dialog --backtitle "Batamiga" --title "Ambiance profile" \
        --radiolist "How much of the v4 ambiance layer do you want?" 15 60 3 \
        full   "Music, sounds, CRT effect, animations" "$([ "$cur" = "full" ] && echo on || echo off)" \
        sound  "Interface sounds only"                 "$([ "$cur" = "sound" ] && echo on || echo off)" \
        quiet  "Nothing extra (best performance)"       "$([ -z "$cur" ] || [ "$cur" = "quiet" ] && echo on || echo off)" \
        2>"$TMP"
    [ -s "$TMP" ] && set_kv batamiga.ambiance "$(cat "$TMP")"
}

theme_menu() {
    local cur
    cur="$(get batamiga.theme_variant)"
    dialog --backtitle "Batamiga" --title "Theme variant" \
        --radiolist "Workbench look" 15 60 3 \
        wb13 "Workbench 1.3 (A500 classic)" "$([ "$cur" = "wb13" ] || [ -z "$cur" ] && echo on || echo off)" \
        wb20 "Workbench 2.0"                "$([ "$cur" = "wb20" ] && echo on || echo off)" \
        wb31 "Workbench 3.1 (AGA)"          "$([ "$cur" = "wb31" ] && echo on || echo off)" \
        2>"$TMP"
    [ -s "$TMP" ] && set_kv batamiga.theme_variant "$(cat "$TMP")"
}

autoconf_menu() {
    local cur
    cur="$(get batamiga.autoconf)"
    dialog --backtitle "Batamiga" --title "Per-game auto-configuration" \
        --yesno "Automatically pick the Amiga model / controller / WHDLoad for known games on launch?\n\nCurrently: $([ "$cur" = "0" ] && echo OFF || echo ON)" 10 60
    case $? in
        0) set_kv batamiga.autoconf 1 ;;
        1) set_kv batamiga.autoconf 0 ;;
    esac
}

network_menu() {
    local cur
    cur="$(get system.security.enabled)"
    dialog --backtitle "Batamiga" --title "Network share" \
        --yesno "Require a password for the network share (\\\\BATOCERA\\share)?\n\nCurrently: $([ "$cur" = "1" ] && echo "protected" || echo "open")" 10 60
    case $? in
        0) set_kv system.security.enabled 1 ;;
        1) set_kv system.security.enabled 0 ;;
    esac
}

rotation_menu() {
    local cur
    cur="$(get display.rotate)"
    dialog --backtitle "Batamiga" --title "Display rotation" \
        --menu "Current: ${cur:-0}" 15 60 4 \
        0 "Normal" \
        1 "90 degrees clockwise" \
        2 "180 degrees" \
        3 "270 degrees clockwise" \
        2>"$TMP"
    [ -s "$TMP" ] && set_kv display.rotate "$(cat "$TMP")"
}

kiosk_menu() {
    local cur
    cur="$(get system.es.menu)"
    dialog --backtitle "Batamiga" --title "Kiosk mode" \
        --yesno "Hide system settings menus (kiosk mode)?\n\nCurrently: $([ "$cur" = "bartop" ] && echo ON || echo OFF)" 10 60
    case $? in
        0) set_kv system.es.menu bartop ;;
        1) set_kv system.es.menu default ;;
    esac
}

main_menu() {
    dialog --backtitle "Batamiga v4/v5 options panel" --title "Batamiga" \
        --menu "Choose a setting to change. Applies on next relaunch/reboot." 18 64 8 \
        1 "Ambiance profile (music, sounds, CRT)" \
        2 "Theme variant (Workbench 1.3 / 2.0 / 3.1)" \
        3 "Per-game auto-configuration" \
        4 "Network share password" \
        5 "Display rotation" \
        6 "Kiosk mode" \
        0 "Exit" \
        2>"$TMP"
    cat "$TMP"
}

while true; do
    choice="$(main_menu)"
    case "$choice" in
        1) ambiance_menu ;;
        2) theme_menu ;;
        3) autoconf_menu ;;
        4) network_menu ;;
        5) rotation_menu ;;
        6) kiosk_menu ;;
        *) clear; exit 0 ;;
    esac
done
