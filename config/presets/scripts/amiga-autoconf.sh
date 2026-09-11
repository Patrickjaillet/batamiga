#!/bin/bash
# Batamiga — EmulationStation custom script wrapper.
# Installed at /userdata/system/scripts/amiga-autoconf.sh (executable).
# ES calls: amiga-autoconf.sh <event> [args...] — see es-core/src/Scripting.cpp
# for the full event list. We only care about "game-start".
exec python3 /usr/share/batocera/datainit/system/scripts/amiga-autoconf.py "$@"
