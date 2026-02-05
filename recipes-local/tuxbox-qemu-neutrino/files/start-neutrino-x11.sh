#!/bin/sh
set -eu

LOG=/var/log/tuxbox-qemu-neutrino.log
mkdir -p "$(dirname "${LOG}")"
exec >>"${LOG}" 2>&1

echo "=== $(date -u +'%Y-%m-%dT%H:%M:%SZ') start ==="
export DISPLAY=:0
export XAUTHORITY=/root/.Xauthority

if [ -z "${SIMULATE_FE:-}" ]; then
    if ! ls /dev/dvb/adapter*/frontend* >/dev/null 2>&1; then
        export SIMULATE_FE=1
        echo "SIMULATE_FE=1 (no DVB frontends detected)"
    fi
fi

VT=7
if command -v chvt >/dev/null 2>&1; then
    chvt "${VT}" || true
fi

set +e
/usr/bin/xinit /bin/sh -c '/usr/bin/neutrino --verbose 3; rc=$?; echo "neutrino exited: $rc"; sleep 2' \
    -- /usr/bin/Xorg :0 -nolisten tcp -keeptty vt${VT}
rc=$?
set -e
echo "xinit exited: $rc"
exit $rc
