#!/bin/sh
set -eu

VT=7
if command -v chvt >/dev/null 2>&1; then
    chvt "${VT}" || true
fi

exec /usr/bin/xinit /usr/bin/neutrino -- /usr/bin/Xorg :0 -nolisten tcp -keeptty vt${VT}
