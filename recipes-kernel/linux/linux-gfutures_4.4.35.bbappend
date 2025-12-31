FILESEXTRAPATHS:prepend := "${OEA-META-GFUTURES-BASE}/recipes-linux/linux-gfutures-${PV}/${MACHINE}:"

# linux-gfutures_4.4.35 keeps defconfigs under per-machine subdirs; make them visible.

PR:append = ".1"
