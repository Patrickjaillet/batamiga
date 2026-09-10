# Hardware test checklist

The offline checks are covered by `scripts/verify-image.sh` (run it on
the `.img` before flashing). The items below need a real boot on the
dedicated PC with the 750 GB USB HDD.

Fill in the result column and copy it back into the internal ROADMAP
(Phase 14 / Phase 18 / Phase 23 / Phase 28).

## Setup

- [ ] `scripts/verify-image.sh <image>` prints `RESULT: PASS`
- [ ] Flash the image to the USB HDD
      (`scripts/flash-usb.ps1 -DiskNumber <N>`)
- [ ] Boot the dedicated PC from USB, EmulationStation starts

## Systems and UI

- [ ] Only `amiga500`, `amiga1200`, `amigacd32` are listed (plus the ES
      utility entries). No other console / computer / arcade system.
- [ ] Default theme renders game lists with boxart + fanart + manual
      once a few games are scraped.
- [ ] Scroll and scrape stay smooth with a few hundred entries.

## Emulation

- [ ] Copy a **legally obtained** Kickstart 1.3 (`kick34005.A500`) and
      3.1 (`kick40068.A1200`, `kick40060.CD32` + `.ext`) to
      `\\BATOCERA\share\bios\amiga`.
- [ ] A500 game that needs KS 1.3: boots and plays (PUAE).
- [ ] A1200 AGA game that needs KS 3.1: boots and plays (PUAE).
- [ ] Same A500 game under **Amiberry** (Options -> Emulator): boots.
- [ ] **AROS**: an A500 or A1200 game that runs with the bundled AROS
      ROM, no Cloanto Kickstart present.
- [ ] **WHDLoad**: a freeware/PD `.lha` WHDLoad title launched end to
      end under Amiberry.
- [ ] **CD32**: a CD image boots; the 7-button CD32 pad works
      (red/blue/green/yellow + shoulders + start).

## Controls

- [ ] A500 default: one-button joystick fires on B; right stick moves
      the mouse; L2/R2 are the mouse buttons.
- [ ] Disk swap works for a multi-disk `.m3u` game.
- [ ] On-screen keyboard reachable for a game that needs typing.

## Maintenance

- [ ] `scripts/backup-userdata.ps1 -Action backup` produces an archive.
- [ ] Restore it to a freshly reflashed drive; games and saves are back.
- [ ] After a reflash + restore, no OTA update has re-added any system.

## Artwork

- [ ] Capture `docs/screenshot.png`: EmulationStation on the Amiga 500
      system with a game list, ideally a game running. 1280x720 or
      larger, PNG.
