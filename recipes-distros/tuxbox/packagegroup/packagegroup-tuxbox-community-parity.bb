# Packagegroup: Tuxbox Community Parity
#
# Optional package set to align with common community image defaults.

DESCRIPTION = "Optional community parity package set for Tuxbox-OS"
LICENSE = "MIT"
PR = "r2"

inherit packagegroup

RDEPENDS:${PN} = " \
    autofs \
    dvb-apps \
    dvbsnoop \
    f2fs-tools \
    gptfdisk \
    hd-idle \
    hdparm \
    jq \
    mtd-utils \
    openvpn \
    rsync \
    smartmontools \
    xfsprogs \
"

# Keep this packagegroup strict to RDEPENDS so default image builds stay stable
# and deterministic with NO_RECOMMENDATIONS = "1".
