FILESEXTRAPATHS:prepend := "${OEA-META-GFUTURES-BASE}/recipes-linux/linux-gfutures-${PV}/${MACHINE}:"

# linux-gfutures_4.4.35 keeps defconfigs under per-machine subdirs; make them visible.

# hd60 defconfig ships without cgroups, but tuxbox distro uses systemd on glibc.
# Keep this minimal to reduce ABI drift for closed-source hd60_* driver modules.
do_configure:prepend:hd60() {
    if [ -f "${WORKDIR}/defconfig" ]; then
        cp -f "${WORKDIR}/defconfig" "${B}/.config"
    fi

    if [ -f "${B}/.config" ] && [ -x "${S}/scripts/config" ]; then
        "${S}/scripts/config" --file "${B}/.config" --enable CGROUPS || true
    fi
}

PR:append = ".3"
