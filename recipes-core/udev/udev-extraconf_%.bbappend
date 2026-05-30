# Tuxbox: mount removable storage under /media so Neutrino, minidlna,
# NFS exports and ofgwrite find /media/hdd, /media/usb and /media/<dev>.
# Upstream default /run/media does not match the rest of the stack.
MOUNT_BASE = "/media"

# Tuxbox: fix poky automount for non-FAT filesystems on systemd images.
# poky's mount.sh automount_systemd() blocks ext4/xfs disks two ways:
#   * it passes "-o silent" unconditionally - ext4/xfs reject that fs option
#     ("Invalid argument"); only FAT accepts it.
#   * systemd-mount auto-adds a systemd-fsck@<dev> precondition; an old e2fsprogs
#     failing on a modern ext4 feature (e.g. orphan_file / FEATURE_C12) then
#     blocks the mount even though the kernel would mount it fine.
# It also runs systemd-mount with --no-block, so an async mount failure is
# reported as success and a stale /tmp/.automount-<dev> is written, which makes
# every later retry (incl. the Neutrino menu via udevadm trigger) a no-op.
# Refs: https://forum.tuxbox-neutrino.org/forum/viewtopic.php?p=388803
do_install:append() {
    mountsh="${D}${sysconfdir}/udev/scripts/mount.sh"

    # Fail loud if poky's layout drifts from what we rewrite below.
    grep -qF 'MOUNT="$MOUNT -o silent"' "$mountsh" || \
        bbfatal "udev-extraconf mount.sh: '-o silent' line not found (poky changed)"
    grep -qF -- '--collect --no-block -t auto' "$mountsh" || \
        bbfatal "udev-extraconf mount.sh: systemd-mount call not found (poky changed)"

    # Drop "-o silent" only inside automount_systemd() (the non-systemd path
    # already guards it for util-linux mount).
    sed -i '/^automount_systemd()/,/^}/ s|^\( *\)MOUNT="\$MOUNT -o silent"|\1# tuxbox: -o silent removed - ext4/xfs reject it via systemd-mount|' "$mountsh"

    # Add --fsck=no (a failing fsck precondition must not block automount; the
    # kernel mounts compat-feature ext4 itself) and drop --no-block (so the
    # return code reflects the real mount result and no stale cache is written).
    sed -i 's|\$MOUNT --collect --no-block -t auto|$MOUNT --fsck=no --collect -t auto|' "$mountsh"

    grep -qF -- '--fsck=no --collect -t auto' "$mountsh" || \
        bbfatal "udev-extraconf mount.sh: --fsck=no rewrite did not apply"
}

PR:append = ".1"
