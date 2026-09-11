#!/bin/bash
# Batamiga — apply a usage profile.
#
#   apply-profile.sh <living|desk|kiosk|kid>
#
# Loads config/profiles/<name>.conf (a plain key=value file, same syntax
# as batocera.conf) and writes each key into
# /userdata/system/batocera.conf via the same idempotent set_kv used by
# the options panel. Called from the first-boot assistant (Phase 26)
# and from the options panel (Phase 24). Full profile definitions land
# in Phase 27; this stub already has the loading/apply logic so Phase
# 27 only needs to add the .conf files.
set -u
PROFILE="${1:?usage: apply-profile.sh <living|desk|kiosk|kid>}"
SRC="/usr/share/batocera/datainit/system/scripts/profiles/${PROFILE}.conf"
CONF=/userdata/system/batocera.conf

if [ ! -f "$SRC" ]; then
    echo "apply-profile: unknown profile '$PROFILE' ($SRC not found)" >&2
    exit 1
fi

set_kv() {
    local key="$1" val="$2"
    if grep -q "^$key=" "$CONF" 2>/dev/null; then
        sed -i "s#^$key=.*#$key=$val#" "$CONF"
    else
        echo "$key=$val" >> "$CONF"
    fi
}

while IFS='=' read -r key val; do
    case "$key" in
        ''|'#'*) continue ;;
    esac
    set_kv "$key" "$val"
done < "$SRC"

set_kv batamiga.profile "$PROFILE"
echo "apply-profile: applied '$PROFILE'"
