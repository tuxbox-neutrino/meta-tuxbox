# Tuxbox-OS QEMU Image Recipe
#
# Lightweight image for QEMU smoke testing (boot/services/shutdown)

require recipes-distros/tuxbox/image/tuxbox-image.inc

DESCRIPTION = "Tuxbox-OS QEMU smoke-test image"
LICENSE = "MIT"

PV = "${DISTRO_VERSION}"
PR = "r8"

# Image variant
IMAGE_BASENAME = "${DISTRO}-qemu-image"

# Give QEMU extra rootfs space for opkg testing (e.g. Neutrino).
TUXBOX_QEMU_ROOTFS_EXTRA_SPACE ?= "1048576"
IMAGE_ROOTFS_EXTRA_SPACE = "${TUXBOX_QEMU_ROOTFS_EXTRA_SPACE}"

# Allow root SSH login with empty password for automated smoke tests.
IMAGE_FEATURES:append = " allow-root-login"

# Keep multiple locales for QEMU convenience.
IMAGE_LINGUAS = "en-us en-gb de-de fr-fr"

# QEMU GUI stack (Neutrino + X11) for interactive testing.
IMAGE_INSTALL:append = " \
    xserver-xorg \
    xinit \
    xf86-video-vesa \
    xf86-video-fbdev \
    tuxbox-qemu-xorgconf \
    tuxbox-qemu-neutrino \
"

# Avoid full multimedia stack in QEMU (relies on SoC EGL providers).
IMAGE_INSTALL:remove = " \
    packagegroup-tuxbox-multimedia \
"

IMAGE_INSTALL:append = " \
    procps \
    iputils-ping \
"

# Produce wic artifacts for runqemu (ext4 is already enabled by qemu machines).
IMAGE_FSTYPES:append = " wic"
