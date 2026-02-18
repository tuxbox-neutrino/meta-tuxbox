# Packagegroup: Tuxbox Community Parity
#
# Optional compatibility wrapper for the community parity extra toolset.

DESCRIPTION = "Optional community parity package set for Tuxbox-OS"
LICENSE = "MIT"
PR = "r3"

inherit packagegroup

RDEPENDS:${PN} = " \
    packagegroup-tuxbox-tools-extra \
"

# Keep this packagegroup strict to RDEPENDS so default image builds stay stable
# and deterministic with NO_RECOMMENDATIONS = "1".
