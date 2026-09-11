#!/usr/bin/env python3
"""
Batamiga — per-game auto-configuration hook.

Installed as an EmulationStation custom script
(/userdata/system/scripts/amiga-autoconf.sh calls this) fired on the
"game-start" event: ES invokes it as
    amiga-autoconf.sh game-start <rom-path> <basename> <system-name>

Looks up the ROM's basename against config/gamedb/amiga.yml (shipped
read-only under /usr/share/batocera/datainit/system/scripts/gamedb/,
copied to /userdata on first boot like everything else in datainit) and
writes a small per-ROM override file that Batocera's configgen already
knows how to read: /userdata/roms/<system>/<rom>.batocera.conf, using
the same "<system>.<key>=<value>" syntax as the global batocera.conf,
scoped to a single game by configgen's own game-level settings lookup.

Never overwrites a file the user (or a previous run) already created —
first run wins, delete the file to let it regenerate.

This is metadata-driven only: the database never contains ROM data,
hashes used to defeat protection, or copyrighted content. See
config/gamedb/amiga.yml's header and the project's legal notes.
"""
import configparser
import pathlib
import re
import sys

GAMEDB = pathlib.Path("/usr/share/batocera/datainit/system/scripts/gamedb/amiga.yml")
ROMS_ROOT = pathlib.Path("/userdata/roms")

# Map our friendly "controller" shorthand to the real puae_model core option.
CONTROLLER_VALUES = {
    "retropad": 1,
    "cd32pad": 517,
    "analog": 773,
    "joystick": 261,
    "keyboard": 259,
}


def load_yaml_min(path: pathlib.Path):
    """Tiny YAML reader for our own controlled subset (avoids depending on
    PyYAML being present on the target). Falls back to PyYAML if available."""
    try:
        import yaml  # type: ignore
        return yaml.safe_load(path.read_text(encoding="utf-8"))
    except ImportError:
        pass
    # Extremely small parser: good enough for our flat list-of-dicts shape.
    # If the real file grows more complex, ship PyYAML instead of this.
    raise RuntimeError("PyYAML not available on target; install python3-yaml")


def find_match(basename: str, system: str, db: dict):
    for entry in db.get("entries", []):
        if entry.get("system") and entry["system"] != system:
            continue
        if re.search(entry["match"], basename, re.IGNORECASE):
            return entry
    # fallback heuristics: simple tag / extension checks
    for h in db.get("fallback_heuristics", []):
        if h.get("applies_to") and system not in h["applies_to"]:
            continue
        tag = h.get("tag")
        ext = h.get("extension")
        if tag and tag.lower() in basename.lower():
            return {"notes": f"fallback tag {tag}", **h.get("set", {})}
        if ext and basename.lower().endswith(ext.lower()):
            return {"notes": f"fallback extension {ext}", **h.get("set", {})}
    return None


def write_override(rom: pathlib.Path, system: str, settings: dict) -> None:
    out = rom.with_suffix(rom.suffix + ".batocera.conf")
    if out.exists():
        return  # never clobber an existing per-game config
    lines = [f"# Batamiga auto-config for {rom.name} (generated, safe to edit or delete)"]
    if "model" in settings:
        lines.append(f"{system}.puae_model={settings['model']}")
    if "controller" in settings:
        val = CONTROLLER_VALUES.get(settings["controller"], settings["controller"])
        lines.append(f"{system}.controller1_puae={val}")
    if settings.get("core") == "amiberry":
        lines.append(f"{system}.emulator=amiberry")
    if settings.get("whdload"):
        lines.append(f"{system}.whdload=config")
    if "puae_cd_turbo" in settings:
        lines.append(f"{system}.puae_cd_speed={'0' if settings['puae_cd_turbo'] else '100'}")
    if len(lines) == 1:
        return  # nothing concrete to write
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    if len(sys.argv) < 4 or sys.argv[1] != "game-start":
        return 0  # only act on game-start; silently ignore other events
    rom_path, basename, system = pathlib.Path(sys.argv[2]), sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else ""
    if system not in ("amiga500", "amiga1200", "amigacd32"):
        return 0
    if not GAMEDB.exists():
        return 0
    try:
        db = load_yaml_min(GAMEDB)
    except Exception as e:
        print(f"amiga-autoconf: could not read game DB: {e}", file=sys.stderr)
        return 0
    match = find_match(basename, system, db)
    if match:
        write_override(rom_path, system, match)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
