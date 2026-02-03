# Tuxbox-OS QEMU Image Recipe
#
# Lightweight image for QEMU smoke testing (boot/services/shutdown)

require recipes-distros/tuxbox/image/tuxbox-image.inc

DESCRIPTION = "Tuxbox-OS QEMU smoke-test image"
LICENSE = "MIT"

PV = "${DISTRO_VERSION}"
PR = "r4"

# Image variant
IMAGE_BASENAME = "${DISTRO}-qemu-image"

# Allow root SSH login with empty password for automated smoke tests.
IMAGE_FEATURES:append = " allow-root-login"

# Keep multiple locales for QEMU convenience.
IMAGE_LINGUAS = "en-us en-gb de-de fr-fr"

# Keep the image lean and QEMU-friendly (no Neutrino/driver stack).
IMAGE_INSTALL:remove = " \
    packagegroup-tuxbox-neutrino \
    neutrino \
    libstb-hal \
    neutrino-plugins \
    packagegroup-tuxbox-multimedia \
"

IMAGE_INSTALL:append = " \
    procps \
    iputils-ping \
"

# Produce wic artifacts for runqemu (ext4 is already enabled by qemu machines).
IMAGE_FSTYPES:append = " wic"
