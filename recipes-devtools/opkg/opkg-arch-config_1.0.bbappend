# opkg-arch-config must stay machine-specific: the generated
# /etc/opkg/arch.conf embeds MACHINE_ARCH (e.g. "arch h7 66").
#
# "inherit allarch" dropped MACHINE_ARCH from the sstate signature, so
# machines sharing a SoC family reused one cached package: H7 images
# shipped the HD51 arch list, opkg then discarded every
# "Architecture: h7" entry from /var/lib/opkg/status on the first
# on-target opkg run (19 packages, among them libc6, libstb-hal,
# ofgwrite, flash-script) and h7 IPKs needed --add-arch h7:66.
#
# Do not fall back to oe-alliance's PACKAGE_ARCH = "${MACHINEBUILD}"
# either: MACHINEBUILD (e.g. zgemmah7) is not part of PACKAGE_ARCHS on
# this distro, so pin the upstream poky behaviour explicitly.
PACKAGE_ARCH = "${MACHINE_ARCH}"

PR:append = ".1"
