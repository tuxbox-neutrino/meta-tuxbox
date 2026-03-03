#!/bin/sh

# Invoked by rc0.d during system poweroff.
[ "$1" = "start" ] || exit 0

mount -t sysfs sys /sys 2>/dev/null || true

if [ -x /usr/bin/turnoff_power ]; then
    /usr/bin/turnoff_power
fi

exit 0
