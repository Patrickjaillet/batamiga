#!/bin/bash
# Batamiga — offline verification of a built .img.
#
# Checks everything that can be checked without booting hardware:
# systems present, default emulator, Amiberry + AROS + evmapy, presets
# injected, datainit free of copyrighted content, boot partition size.
#
#   scripts/verify-image.sh /path/to/batocera-x86_64-*.img
#
# Exits non-zero on the first failed check. Meant to gate CI (Phase 15)
# and to stand in for the "no other system present" and "presets applied"
# items of Phase 14.

set -u
IMG="${1:?usage: verify-image.sh <image.img>}"
[ -r "$IMG" ] || { echo "FAIL: cannot read $IMG"; exit 2; }

# host tools from the buildroot output, if present, else system ones
for d in "$(dirname "$IMG")"/../../../../host/bin \
         "$HOME"/batocera/batocera.linux/output/amiga500only/host/bin; do
  [ -d "$d" ] && PATH="$d:$PATH"
done
export MTOOLS_SKIP_CHECK=1

fail=0
ok()   { printf '  ok   %s\n' "$1"; }
bad()  { printf '  FAIL %s\n' "$1"; fail=1; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

echo "== partitions =="
# boot partition (partition 1) start + size
read -r START SECTORS <<<"$(partx -o START,SECTORS -g -r "$IMG" 2>/dev/null | head -1)"
if [ -n "${START:-}" ]; then
  MIB=$(( SECTORS / 2048 ))
  [ "$MIB" -ge 3900 ] && [ "$MIB" -le 4200 ] \
    && ok "boot partition ${MIB} MiB (~4G as patched)" \
    || bad "boot partition ${MIB} MiB (expected ~4096)"
else
  bad "could not read partition table"
fi

echo "== extract squashfs =="
OFF=$(( ${START:-2048} * 512 ))
if ! mcopy -i "$IMG@@${OFF}" ::/boot/batocera "$W/sq.img" 2>/dev/null; then
  bad "could not copy boot/batocera from the image"; echo; echo "RESULT: FAIL"; exit 1
fi
unsquashfs -q -f -d "$W/root" "$W/sq.img" \
  'usr/bin/amiberry' \
  'usr/share/amiberry' \
  'usr/share/evmapy' \
  'usr/share/emulationstation/es_systems.cfg' \
  'usr/share/batocera/datainit' >/dev/null 2>&1
R="$W/root"

echo "== systems =="
CFG="$R/usr/share/emulationstation/es_systems.cfg"
mapfile -t SYS < <(grep -oP '(?<=<name>)[^<]+' "$CFG" | sort)
printf '  systems: %s\n' "${SYS[*]}"
for want in amiga500 amiga1200 amigacd32; do
  printf '%s\n' "${SYS[@]}" | grep -qx "$want" && ok "$want present" || bad "$want missing"
done
# only the three Amiga systems + ES built-in utilities, nothing else
ALLOWED='amiga500 amiga1200 amigacd32 flatpak imageviewer library odcommander ports recordings'
for s in "${SYS[@]}"; do
  case " $ALLOWED " in *" $s "*) : ;; *) bad "unexpected system: $s" ;; esac
done
grep -q '<name>amigacdtv</name>' "$CFG" && bad "amigacdtv should be absent" || ok "amigacdtv absent"

echo "== default emulator =="
for s in amiga500 amiga1200 amigacd32; do
  blk="$(awk "/<name>$s<\/name>/,/<\/system>/" "$CFG")"
  echo "$blk" | grep -q '<core default="true">puae</core>' \
    && ok "$s: puae is the default core" \
    || bad "$s: puae is not marked default"
done

echo "== amiberry + AROS + mappings =="
[ -x "$R/usr/bin/amiberry" ] && ok "/usr/bin/amiberry" || bad "amiberry binary missing"
[ -d "$R/usr/share/amiberry/whdboot" ] && ok "amiberry whdboot/" || bad "amiberry whdboot/ missing"
[ -d "$R/usr/share/amiberry/data" ] && ok "amiberry data/" || bad "amiberry data/ missing"
for f in aros-rom.bin aros-ext.bin; do
  [ -s "$R/usr/share/batocera/datainit/bios/amiga/$f" ] \
    && ok "AROS $f" || bad "AROS $f missing"
done
for f in amiga500 amiga1200 amigacd32; do
  [ -s "$R/usr/share/evmapy/$f.amiberry.keys" ] \
    && ok "evmapy $f.amiberry.keys" || bad "evmapy $f.amiberry.keys missing"
done

echo "== presets =="
CONF="$R/usr/share/batocera/datainit/system/batocera.conf"
n=$(grep -c 'BATAMIGA PRESETS' "$CONF" 2>/dev/null || echo 0)
[ "$n" = 2 ] && ok "one BATAMIGA PRESETS block" || bad "expected 2 markers, found $n"
grep -qE '^amiga500\.core=puae'       "$CONF" && ok "amiga500 preset"  || bad "amiga500 preset missing"
grep -qE '^amiga1200\.core=puae'      "$CONF" && ok "amiga1200 preset" || bad "amiga1200 preset missing"
grep -qE '^amigacd32\.puae_model=CD32FR' "$CONF" && ok "amigacd32 preset" || bad "amigacd32 preset missing"
grep -qE '^updates\.enabled=0'        "$CONF" && ok "OS updates disabled" || bad "updates.enabled=0 missing"
# no duplicate active key from an overridden upstream line
dups=$(grep -oE '^[a-z][a-z0-9._]+=' "$CONF" | sort | uniq -d)
[ -z "$dups" ] && ok "no duplicate active keys" || bad "duplicate keys: $dups"

ES="$R/usr/share/batocera/datainit/system/configs/emulationstation/es_settings.cfg"
[ -s "$ES" ] && grep -q 'ScreenScraper' "$ES" && ok "es_settings.cfg (ScreenScraper)" \
  || bad "es_settings.cfg missing or not ScreenScraper"
COLL="$R/usr/share/batocera/datainit/.emulationstation/collections"
for c in CD32 AGA WHDLoad Demos; do
  [ -f "$COLL/custom-$c.cfg" ] && ok "collection $c" || bad "collection $c missing"
done

echo "== datainit is free of content =="
G="$R/usr/share/batocera/datainit"
for d in roms/amiga500 roms/amiga1200 roms/amigacd32; do
  extra=$(find "$G/$d" -type f ! -name '_info.txt' 2>/dev/null | wc -l)
  [ "$extra" = 0 ] && ok "$d empty (only _info.txt)" || bad "$d has $extra content file(s)"
done
kick=$(find "$G/bios/amiga" -type f ! -name 'aros-*.bin' 2>/dev/null | wc -l)
[ "$kick" = 0 ] && ok "bios/amiga has AROS only, no Kickstart" || bad "bios/amiga has $kick non-AROS file(s)"

echo
if [ "$fail" = 0 ]; then echo "RESULT: PASS"; else echo "RESULT: FAIL"; fi
exit "$fail"
