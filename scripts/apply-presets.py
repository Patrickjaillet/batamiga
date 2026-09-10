#!/usr/bin/env python3
"""
Batamiga — inject the project presets into the Batocera clone's datainit
tree, so a freshly flashed image boots with the right per-system
defaults, scraper settings and collections.

Run from the batocera.linux clone root (WSL):

    python3 /mnt/c/Users/Patrick/Desktop/Batomiga/scripts/apply-presets.py

It is idempotent: re-running replaces the Batamiga block / files rather
than appending twice. After running, rebuild the affected packages:

    CMD=batocera-system-rebuild BATCH_MODE=1 make amiga500only-build
    CMD=batocera-userdatainit-rebuild BATCH_MODE=1 make amiga500only-build

then rebuild the image.
"""
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent          # Batomiga/
PRESETS = REPO / "config" / "presets"

# The clone root: either passed as argv[1], or the cwd.
CLONE = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path.cwd()

BEGIN = "# >>> BATAMIGA PRESETS >>>"
END = "# <<< BATAMIGA PRESETS <<<"


def _keys_in(block: str) -> set:
    """Config keys (left of '=') assigned in the preset block."""
    keys = set()
    for line in block.splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            keys.add(line.split("=", 1)[0].strip())
    return keys


def splice(target: pathlib.Path, block: str) -> None:
    """Replace the text between BEGIN/END markers in target (or append it),
    and comment out any upstream line outside the block that assigns a key
    the block also sets, so there is exactly one active assignment."""
    text = target.read_text(encoding="utf-8") if target.exists() else ""

    # strip a previous Batamiga block so we compare against clean upstream
    if BEGIN in text and END in text:
        pre = text[: text.index(BEGIN)].rstrip("\n")
        post = text[text.index(END) + len(END):].lstrip("\n")
        text = (pre + "\n" + post) if post else pre + "\n"

    keys = _keys_in(block)
    out = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("#") and "=" in stripped:
            key = stripped.split("=", 1)[0].strip()
            if key in keys:
                out.append("# [batamiga: overridden below] " + line)
                continue
        out.append(line)
    text = "\n".join(out).rstrip("\n")

    marked = f"{BEGIN}\n{block.rstrip()}\n{END}\n"
    text = text + "\n\n" + marked
    target.write_text(text, encoding="utf-8")
    print(f"  spliced presets into {target.relative_to(CLONE)}")


def copy(src: pathlib.Path, dst: pathlib.Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(src.read_bytes())
    print(f"  {dst.relative_to(CLONE)}")


def main() -> int:
    sysdir = CLONE / "package" / "batocera" / "core" / "batocera-system"
    udi = CLONE / "package" / "batocera" / "core" / "batocera-userdatainit" / "datainit"
    if not sysdir.is_dir() or not udi.is_dir():
        print(f"error: {CLONE} does not look like a batocera.linux clone", file=sys.stderr)
        return 1

    print("1. per-system defaults -> batocera-system/batocera.conf")
    splice(sysdir / "batocera.conf", (PRESETS / "batamiga.conf").read_text(encoding="utf-8"))

    print("2. EmulationStation settings -> datainit")
    copy(PRESETS / "es_settings.cfg",
         udi / "system" / "configs" / "emulationstation" / "es_settings.cfg")

    print("3. custom collections -> datainit")
    for cfg in sorted((PRESETS / "collections").glob("custom-*.cfg")):
        copy(cfg, udi / ".emulationstation" / "collections" / cfg.name)

    print("4. rom folder placeholders -> datainit")
    for info in sorted((PRESETS / "roms").glob("*/_info.txt")):
        system = info.parent.name
        copy(info, udi / "roms" / system / "_info.txt")

    print("done. Rebuild batocera-system + batocera-userdatainit, then the image.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
