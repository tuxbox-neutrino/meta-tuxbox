#!/bin/sh
set -eu

if [ -d /etc/local.d ]; then
    for f in /etc/local.d/*; do
        [ -e "${f}" ] || break
        if [ -x "${f}" ]; then
            "${f}"
        fi
    done
fi

exit 0
