#!/bin/sh

# Set a Debian-like prompt for interactive shells.
case "$-" in
    *i*)
        if [ -n "${BASH_VERSION:-}" ]; then
            PS1='\u@\h:\w\$ '
        else
            PS1='\u@\h:\w\$ '
        fi
        export PS1
        ;;
esac
