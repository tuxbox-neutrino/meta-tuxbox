# Tuxbox: mount removable storage under /media so Neutrino, minidlna,
# NFS exports and ofgwrite find /media/hdd, /media/usb and /media/<dev>.
# Upstream default /run/media does not match the rest of the stack.
MOUNT_BASE = "/media"

PR:append = ".0"
