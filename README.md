# Batamiga

A bootable USB image based on **Batocera Linux**, stripped down to
**Amiga emulation only**. Three systems are exposed in EmulationStation:

| EmulationStation system | Machine             | Default emulator | Also available |
|-------------------------|---------------------|------------------|----------------|
| `amiga500`              | Amiga 500 (OCS/ECS) | libretro **puae** | Amiberry |
| `amiga1200`             | Amiga 1200 (AGA)    | libretro **puae** | Amiberry |
| `amigacd32`             | Amiga CD32          | libretro **puae** | Amiberry |

Two emulation engines: **PUAE** (libretro core, the default — simple and
light) and **Amiberry** (better for WHDLoad, AGA, cycle-exact timing and
CD32). Switch per game from *Options -> Emulator*.

No other console / computer / arcade system is built or displayed. The
default Batocera EmulationStation theme is kept untouched — there is no
visual customization.

- Architecture: **x86_64 EFI**
- Base: `batocera-x86_64.board` (Batocera 44-dev)
- Image: `image/batocera-x86_64-44-*.img` (~4.8 GB, uncompressed)
- Per-system defaults, scraper config and helper collections are baked
  in; the image itself ships **no games and no Kickstart ROMs**.

> Personal use only. Do not publicly redistribute the image. Amiga
> Kickstart ROMs are copyrighted (Cloanto) — see the BIOS section.

---

## 1. Flash the image to a USB drive

The image ships **without games and without BIOS files** — it is a clean
base. Content is copied after the first boot (sections 3 and 4).

### Option A — bundled script (Windows, recommended)

In **PowerShell running as Administrator**:

```powershell
# 1. identify the target disk number
Get-Disk

# 2. flash (replace <N> with the USB disk number)
cd path\to\Batamiga
powershell -ExecutionPolicy Bypass -File .\scripts\flash-usb.ps1 -DiskNumber <N>
```

The script prints the target disk details, asks for confirmation
(`OUI` in capitals), runs `diskpart clean`, then writes the raw image
sector by sector to `\\.\PhysicalDrive<N>`. It also accepts a `.img.gz`
image (decompressed on the fly) via `-ImagePath`.

> **DESTRUCTIVE**: every byte on the target disk is erased. Double-check
> the disk number (`Get-Disk`) before confirming.

### Option B — balenaEtcher (Windows)

Open Etcher -> *Flash from file* -> `image\batocera-x86_64-44-*.img`
-> select the USB disk -> *Flash*.

### Option C — dd (Linux / WSL)

```bash
sudo dd if=batocera-x86_64-44-<date>.img of=/dev/sdX bs=4M status=progress conv=fsync
```

From WSL2 you must first attach the USB disk with `usbipd`
(`usbipd list`, `usbipd bind --busid <x>`, `usbipd attach --wsl --busid <x>`).

### After flashing

The drive holds two partitions:

- **BATOCERA** (~4 GB, FAT32) — kernel, EFI, compressed system
  (`boot/batocera`)
- **SHARE** (ext4) — empty at first; Batocera **grows it automatically on
  the first boot** to fill the rest of the disk, and creates the
  `/userdata` tree there (`roms/`, `bios/`, `saves/`, ...).

Eject the drive cleanly before removing it.

---

## 2. First boot

1. Plug the drive into the target machine and boot from it (boot menu ->
   USB device; enable *UEFI boot* / disable *Secure Boot* if needed).
2. Batocera resizes SHARE, then launches EmulationStation. The three
   Amiga systems appear (even with no games installed).
3. Shut down cleanly from the menu (`Start` -> *Quit* -> *Shutdown*) so
   the `/userdata` tree is fully written.

The display uses the **normal orientation (0 degrees)**. For an
upside-down panel: `Menu` -> *System settings* -> *Display*, or edit
`display.rotate` (`0`/`1`/`2`/`3`) in `/userdata/system/batocera.conf`.

---

## 3. Adding games

Copy files into the matching system folder on the **SHARE** partition:

```text
/userdata/roms/amiga500/
/userdata/roms/amiga1200/
/userdata/roms/amigacd32/
```

Three ways to reach it:

- **Network (Samba)**: from a PC on the same network, open
  `\\BATOCERA\share` (Windows) or `smb://batocera/share` — folders
  `roms/amiga500`, etc.
- **SSH / SCP**: `scp game.zip root@batocera:/userdata/roms/amiga500/`
  (login `root`, default password `linux`).
- **Directly**: plug the drive into a Linux PC (the SHARE partition is
  ext4, not readable by Windows without a third-party driver).

From Windows, `scripts/push-games.ps1` copies a whole folder over SSH:

```powershell
.\scripts\push-games.ps1 -System amiga500 -Source "D:\Amiga\A500 games"
```

### Supported formats

| System | Formats |
|--------|---------|
| `amiga500` / `amiga1200` | `.adf` `.adz` `.dms` `.ipf` (IPF/CAPS — libcapsimage bundled) `.hdf` `.lha` `.zip` `.m3u` (multi-disk) `.uae` `.scp` `.raw` |
| `amigacd32` | `.iso` `.cue` (+`.bin`) `.chd` `.nrg` |

For multi-disk games, list the disk images in a `.m3u` file (one path
per line) and add the `.m3u` to the roms folder.

### WHDLoad (hard-disk installs)

Drop a WHDLoad `.lha` archive (or an `.hdf`) into `roms/amiga500` or
`roms/amiga1200`. **Amiberry** runs these natively via its bundled
`whdboot`. **PUAE** needs its WHDLoad launcher, which is already enabled
in this image (`whdload=config`). A "WHDLoad" collection is pre-created
to group them.

After copying: in EmulationStation, `Start` -> *Update gamelists* (or
reboot).

---

## 4. Kickstart BIOS files (required)

**Not included** — copyrighted (Cloanto). Obtain them legally, for
example via **[Amiga Forever](https://www.amigaforever.com/)**.

Copy them into the following folder on the SHARE partition:

```text
/userdata/bios/amiga/
```

Both emulators look for Amiga Forever and TOSEC ROMs. Useful names
(case-sensitive):

| File                 | Purpose |
|----------------------|---------|
| `kick34005.A500`     | Kickstart 1.3 (rev 34.005) — most common for the A500 |
| `kick40068.A1200`    | Kickstart 3.1 — Amiga 1200 |
| `kick40060.CD32`     | Kickstart 3.1 — Amiga CD32 |
| `kick40060.CD32.ext` | CD32 extended ROM (CD drive + Akiko) |

The equivalent Amiga Forever names are also recognized
(`kick33180.A500`, `kick37175.A500`), including the encrypted ROM set
plus its `rom.key`. See <https://wiki.batocera.org/systems:amiga500> for
the full list and expected checksums.

### AROS — no ROM needed to get started

This image bundles **AROS** (`aros-rom.bin` / `aros-ext.bin`), an
open-source Kickstart replacement. Amiga 500 and Amiga 1200 boot and run
many games with AROS alone — useful before you add real Kickstarts.
**CD32 still requires a genuine CD32 Kickstart** (AROS does not cover
it).

Without a suitable Kickstart (and no AROS fallback), a game shows a
blank screen or stays stuck on the "ROM not found" splash.

---

## 5. Default controls and per-system presets

This image pre-configures each system so games "just run":

| System | Model | Controller |
|--------|-------|------------|
| `amiga500`  | A500, KS 1.3, 512K+512K, "more compatible" CPU | 1-button joystick (port 1) + mouse |
| `amiga1200` | A1200 AGA, KS 3.1, 2M chip + 8M fast           | 1-button joystick (port 1) + mouse |
| `amigacd32` | CD32 + Fast RAM, AGA + Akiko                   | 7-button CD32 pad (port 1) |

Common mapping:

- **D-pad / left stick** -> joystick directions
- **B (down face button)** -> fire; second fire button acts as "up"
  (jump) on A500/A1200
- **Right stick** -> mouse; **L2 / R2** -> left / right mouse button
- **Select + Start** -> in-emulator menu (RetroArch RGUI for PUAE) to
  remap, swap disks, change the model, etc.
- USB keyboard recognized directly. An on-screen keyboard is available
  (RetroArch VKBD for PUAE; `amiberry_virtual_keyboard` for Amiberry).

Every preset is only a default — override any of it from *Options* on a
game, or from the system settings. Per-game fine-tuning for PUAE:
*Options -> Core options* (`puae_model`, `puae_floppy_speed`,
`cpu_compatibility`, ...).

---

## 6. Scraping metadata and artwork

The image is pre-set to scrape from **ScreenScraper** (boxart, logo,
snapshot, fanart, manual, video, and pad-to-key mappings). You still
need a free ScreenScraper account:

1. `Start` -> *Scraper* -> *Settings* -> enter your username / password.
2. Back out, `Start` -> *Scraper* -> *Scrape now*.

Four custom collections are pre-created and filled as you tag or scrape
games: **CD32**, **AGA**, **WHDLoad**, **Demos**.

---

## 7. Backup, restore and updating

`scripts/backup-userdata.ps1` archives everything on the SHARE partition
(games, BIOS, saves, configs, collections) over SSH:

```powershell
.\scripts\backup-userdata.ps1 -Action backup  -Out "D:\Batamiga-backups"
.\scripts\backup-userdata.ps1 -Action restore -Archive "D:\Batamiga-backups\userdata-<stamp>.tar.gz"
```

**Updating the image**: automatic Batocera system updates are disabled
on purpose (an update would regenerate the system list and bring every
stock emulator back). To move to a newer Batamiga image: back up
`/userdata`, flash the new image, restore `/userdata`.

The network share is open (no password) for convenience on a trusted
home LAN. To lock it down: set `system.security.enabled=1` in
`/userdata/system/batocera.conf` and run `passwd` over SSH.

---

## 8. Rebuilding the image

Everything happens on the **WSL Ubuntu** side, in
`~/batocera/batocera.linux` (Batocera sources + buildroot submodule).
Full details and the history of fixes live in the internal working
document (not published).

Files from this repo re-applied on a fresh clone:

| File in `config/`                        | Target in the clone |
|------------------------------------------|---------------------|
| `batocera-amiga500only.board`            | `configs/` (defines the `amiga500only` target) |
| `amiga500only-es_systems.patch`          | `package/batocera/emulationstation/batocera-es-system/es_systems.yml` (removes `amigacdtv`) |
| `buildroot-rust-1.96.0.patch`            | `buildroot` submodule (rustc too old for `cargo-c`) |
| `gtk-layer-shell-wayland-select.patch`   | `package/batocera/gpu/gtk-layer-shell/Config.in` |
| `batocera-system-rclone-disable.patch`   | `package/batocera/core/batocera-system/Config.in` (rclone broken upstream) |
| `genimage-boot-4g.patch`                 | `board/batocera/x86/genimage-boot.cfg` (boot partition 10G -> 4G) |
| `amiberry-deps-select.patch`             | `package/batocera/emulators/amiberry/Config.in` (adds missing `select` for libpcap / libcurl / json-for-modern-cpp) |
| `scripts/patch-postimage.py`             | disables gzip compression of the final image |
| `scripts/apply-presets.py`               | injects `config/presets/` (per-system defaults, `es_settings.cfg`, collections, rom `_info.txt`) into the datainit tree |

Build:

```bash
cd ~/batocera/batocera.linux
sudo service docker start                      # no systemd -> re-run per session
python3 /path/to/Batamiga/scripts/apply-presets.py .   # once, before building
BATCH_MODE=1 make amiga500only-build           # first run: several hours
```

Iterating on a single package (much faster):

```bash
CMD=<package> BATCH_MODE=1 make amiga500only-build
# e.g. CMD=libretro-puae, CMD=batocera-es-system-rebuild
```

> **Known pitfalls**: always prefix `BATCH_MODE=1`; a change under
> `package/*/` for an already-built package is not re-detected -> use
> `CMD=<package>-rebuild`; the WSL clock can drift -> regenerate the
> defconfig with `bash configs/createDefconfig.sh ...` + `touch`.

Output image:
`output/amiga500only/images/batocera/images/x86_64/batocera-x86_64-44-*.img`

### Verifying a build

Before flashing, run the offline checks:

```bash
scripts/verify-image.sh output/amiga500only/images/batocera/images/x86_64/batocera-x86_64-44-*.img
```

It confirms the systems present, the default emulator, Amiberry + AROS,
the injected presets, and that the image ships no games or Kickstart.
Hardware tests that need a real boot are listed in
[docs/test-checklist.md](docs/test-checklist.md).

---

## Repository layout

```text
Batamiga/
├── README.md           # this file
├── CHANGELOG.md         # Keep a Changelog + SemVer
├── LICENSE
├── CONTRIBUTING.md
├── config/
│   ├── *.board          # custom build target
│   ├── *.patch          # upstream fixes to re-apply on a fresh clone
│   └── presets/         # per-system defaults, es_settings, collections, rom _info.txt
├── scripts/             # USB flashing, preset injection, game push, userdata backup, diagnostics
├── docs/                # screenshots and user-facing site sources
├── image/               # compiled image (.img + .sha256) — not versioned when large
└── build/               # documentary reference (real sources live in WSL)
```

---

## License

Copyright (c) 2026 Patrick JAILLET. All rights reserved. See
[LICENSE](LICENSE).

- E-mail: <sandefjord.development@proton.me>
- Web: <https://patrickjaillet.github.io/batamiga>

Batocera Linux, RetroArch, PUAE and Amiberry are the property of their
respective authors and ship under their own licenses.
