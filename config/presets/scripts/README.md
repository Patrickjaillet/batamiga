# Batamiga embedded scripts

Scripts written ahead of the phases that build/inject them, so their
logic is already tested. Not yet wired into a build — see the ROADMAP
phase noted per file for the injection point (`apply-presets.py` /
`apply-theme.py`, still to be extended) and the target path under
`/usr/share/batocera/datainit/`.

| File | ES hook / launcher | Target path (datainit) | Phase |
|------|--------------------|--------------------------|-------|
| `amiga-autoconf.sh` + `.py` + `gamedb/amiga.yml` | `game-start` event | `system/scripts/amiga-autoconf.sh` (+ `.py`, `gamedb/`) | 16 |
| `batamiga-panel.sh` | launched as a `ports` entry | `system/scripts/batamiga-panel.sh` | 24 |
| `batamiga-import.sh` + `kickstart-hashes.txt` | called by the panel / setup assistant | `system/scripts/batamiga-import.sh` | 25 |
| `apply-profile.sh` + `profiles/*.conf` | called by the panel / setup assistant | `system/scripts/apply-profile.sh` (+ `profiles/`) | 27 |
| `batamiga-setup.sh` + `setup/strings/*.sh` | `start` event, first boot only | `system/scripts/batamiga-setup.sh` (+ `setup/`) | 26 |

## How each hook fires

EmulationStation's `Scripting::fireEvent` (`es-core/src/Scripting.cpp`)
runs every executable file found in
`~/.emulationstation/scripts/<event-name>/` — no fork of ES needed.
Batocera also exposes a plain custom-script convention documented in
`datainit/system/scripts/template-game-start-stop.txt`: drop an
executable in `/userdata/system/scripts/`, it receives the event name as
`$1` and event-specific arguments after it. `game-start` gets
`(rom, basename, systemName)`; only `start` (ES launch) and `game-start`
are used here.

## Testing without a build

Each script was validated in isolation (sandboxed paths, no real
Batocera environment) before being committed — see the session notes in
ROADMAP.md for the exact test transcripts. `amiga-autoconf.py` and
`gamedb/amiga.yml` can be re-tested any time with plain Python + PyYAML:

```bash
python3 -c "import yaml; yaml.safe_load(open('gamedb/amiga.yml'))"
```

The shell scripts are POSIX-ish bash; `bash -n <file>` catches syntax
errors without executing anything. `batamiga-panel.sh` and
`batamiga-setup.sh` call `dialog(1)`, which is part of stock Batocera
but not available on a plain WSL Ubuntu — their non-interactive logic
(the `get`/`set_kv` helpers, the step/marker resume logic) is written to
be testable by extracting just those functions, which is what the
session tests did.
