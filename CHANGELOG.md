# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Working toward a reference-grade Amiga / CD32 system (target: `v2.0.0`).

### Added
- English `README.md`, `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`,
  `.gitignore`, `docs/`.

### Changed
- Project name settled as **Batamiga** across all published files.

## [1.1.0] - 2026-09-11

Two emulation engines, per-system presets, scraper and collections.
Still no bundled games or Kickstart ROMs.

### Added
- **Amiberry** (v8.3.0) as a second emulation engine alongside PUAE,
  plus bundled **AROS** open-source Kickstart (A500 / A1200 boot with no
  copyrighted ROM). `BR2_PACKAGE_AMIBERRY=y` in the custom board.
- Per-system presets baked into the image: correct Amiga model per
  system (A500 / A1200 AGA / CD32+FastRAM), one-button joystick + mouse
  for A500/A1200, 7-button CD32 pad for CD32, WHDLoad launcher enabled,
  PAL auto.
- Pre-configured ScreenScraper settings and four custom collections
  (CD32, AGA, WHDLoad, Demos). No credentials shipped.
- `scripts/push-games.ps1` (SCP a game folder to the device),
  `scripts/backup-userdata.ps1` (backup/restore `/userdata`),
  `scripts/apply-presets.py` (inject presets at build time).

### Changed
- PUAE stays the default emulator/core for all three systems
  (`<core default="true">puae</core>`); Amiberry is opt-in per game.
- Automatic Batocera OS updates disabled (an update would regenerate the
  system list and re-expose every stock emulator).

### Fixed
- `amiberry/Config.in` missing `select` for `libpcap`, `libcurl` and
  `json-for-modern-cpp` — broke the minimal-image build. Same class as
  the earlier `gtk-layer-shell` fix.

## [1.0.0] - 2026-09-10

First working image. Predates this repository — no git tag; recorded
here for continuity.

### Added
- Batocera Linux (x86_64 EFI, base `batocera-x86_64.board`, 44-dev)
  reduced to Amiga emulation only.
- Three EmulationStation systems: `amiga500`, `amiga1200`, `amigacd32`,
  all backed by the single compiled emulator `libretro-puae`.
- `libcapsimage` for `.ipf` (IPF preservation) disk support.
- Custom build target `amiga500only` via
  `config/batocera-amiga500only.board` (name suffix is historical).
- USB flashing script `scripts/flash-usb.ps1` (raw write, optional gzip
  decompression, `diskpart clean`).

### Changed
- Master switch `BR2_PACKAGE_BATOCERA_ALL_SYSTEMS` disabled; only
  RetroArch + PUAE selected.
- `es_systems.yml`: `amigacdtv` system definition removed (PUAE would
  otherwise expose it); `amiga500`, `amiga1200`, `amigacd32` kept.
- Kodi and the live bezel overlay tool removed from the custom board
  (both pulled a Wayland desktop stack out of scope).
- Boot partition shrunk from 10 GB to 4 GB.
- Final image is no longer gzip-compressed.
- Display rotation left at the default `0`.

### Removed
- All non-Amiga emulator cores and non-essential packages.
- Bundled games and Kickstart ROMs — the image is a clean base; the user
  supplies their own content on first boot.

### Fixed
- `cargo-c` build failure: bumped bundled Rust from 1.95.0 to 1.96.0
  (`buildroot/utils/update-rust`).
- `gtk-layer-shell` not propagating its Wayland dependency through
  Kconfig: added `select BR2_PACKAGE_WAYLAND` to its `Config.in`.
- `libva` rebuilt with Wayland support after a cross-cutting config
  change left it stale (`CMD=libva-reconfigure`).
- `rclone` broken upstream (invalid Go module pseudo-version): its
  unconditional `select` commented out in `batocera-system/Config.in`.

[Unreleased]: https://github.com/patrickjaillet/batamiga/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/patrickjaillet/batamiga/releases/tag/v1.1.0
[1.0.0]: https://github.com/patrickjaillet/batamiga/blob/main/CHANGELOG.md#100---2026-09-10
