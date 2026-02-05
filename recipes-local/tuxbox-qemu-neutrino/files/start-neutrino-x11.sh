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
/usr/bin/xinit /bin/sh -c '
    echo "xrandr pre-neutrino:"
    /usr/bin/xrandr --query || true
    OUT=$(/usr/bin/xrandr --query 2>/dev/null | awk "/ connected/{print \$1; exit}")
    if [ -n "${OUT}" ]; then
        /usr/bin/xrandr --output "${OUT}" --mode 1280x720 || \
            /usr/bin/xrandr --output "${OUT}" --mode 1024x768 || true
        /usr/bin/xrandr --output "${OUT}" --fb 1280x720 || true
    else
        /usr/bin/xrandr --size 1280x720 || true
    fi
    echo "xrandr post-neutrino:"
    /usr/bin/xrandr --query || true
    /usr/bin/neutrino --verbose 3; rc=$?; echo "neutrino exited: $rc"; sleep 2' \
    -- /usr/bin/Xorg :0 -nolisten tcp -keeptty vt${VT}
rc=$?
set -e
echo "xinit exited: $rc"
exit $rc
