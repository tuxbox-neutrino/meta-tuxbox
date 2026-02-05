#!/bin/sh
set -eu

exec /usr/bin/xinit /usr/bin/neutrino -- /usr/bin/Xorg :0 -nolisten tcp -keeptty vt7
