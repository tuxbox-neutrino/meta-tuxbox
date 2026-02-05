#!/bin/sh
set -eu

exec /usr/bin/xinit /usr/bin/neutrino -- :0 -nolisten tcp vt7
