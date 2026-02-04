#!/bin/sh
set -eu

STATE_DIR="/var/lib/tuxbox"
MARKER="${STATE_DIR}/firstboot.done"

if [ -f "${MARKER}" ]; then
    exit 0
fi

mkdir -p "${STATE_DIR}"

if [ -d /etc/firstboot.d ]; then
    for f in /etc/firstboot.d/*; do
        [ -e "${f}" ] || break
        if [ -x "${f}" ]; then
            "${f}"
        fi
    done
fi

touch "${MARKER}"
exit 0
