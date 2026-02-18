# Packagegroup: Tuxbox Core Tools
#
# Curated default admin/runtime tools for a balanced STB base image.

DESCRIPTION = "Tuxbox-OS core tools package set"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS:${PN} = " \
    bash \
    cronie \
    findutils \
    grep \
    hdparm \
    htop \
    jq \
    less \
    mtd-utils \
    nano \
    procps \
    rsync \
    tuxbox-feed-config \
"
