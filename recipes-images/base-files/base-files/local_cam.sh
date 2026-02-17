#!/bin/sh

local_bindir="/etc/neutrino/bin"
bindir="/usr/bin"

is_internal_oscam_link() {
        [ -L "$1" ] && [ "$(readlink -- "$1")" = "${1}.internal" ]
}

for cam in oscam cccam gbox; do
        if [ -x "${local_bindir}/${cam}" ]; then
                if [ "$cam" = "oscam" ]; then
                        if is_internal_oscam_link "${bindir}/${cam}"; then
                                ln -sf "${local_bindir}/${cam}" "${bindir}/${cam}"
                        fi
                else
                        [ ! -L "${bindir}/${cam}" ] && ln -sf "${local_bindir}/${cam}" "${bindir}/${cam}"
                fi
        else
                if [ "$cam" = "oscam" ]; then
                        if ! is_internal_oscam_link "${bindir}/${cam}"; then
                                ln -sf "${bindir}/${cam}.internal" "${bindir}/${cam}"
                        fi
                else
                        [ -L "${bindir}/${cam}" ] && rm -f -- "${bindir}/${cam}"
                fi
        fi
done

exit 0
