#!/usr/bin/env python3
"""Desactive la compression gzip de l'image dans le post-image script de
Batocera (inutile pour un flash local, le script de flash decompresse a
la volee de toute facon). Idempotent."""
import pathlib
import sys

p = pathlib.Path(sys.argv[1] if len(sys.argv) > 1
                 else 'board/batocera/scripts/post-image-script.sh')
s = p.read_text()

old = '    gzip "${BATOCERAIMG}" || exit 1'
new = '    : # BATAMIGA: gzip desactive (flash local)'
if old in s:
    s = s.replace(old, new)
    print('gzip line: patched')
elif new in s:
    print('gzip line: already patched')
else:
    sys.exit('gzip line: PATTERN NOT FOUND')

s = s.replace('"/batocera-"*".img.gz"', '"/batocera-"*".img"')
p.write_text(s)
print('done')
