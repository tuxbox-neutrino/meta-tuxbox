# Tuxbox-OS QEMU Image Recipe
#
# Lightweight image for QEMU smoke testing (boot/services/shutdown)

require recipes-distros/tuxbox/image/tuxbox-image.inc

DESCRIPTION = "Tuxbox-OS QEMU smoke-test image"
LICENSE = "MIT"

PV = "${DISTRO_VERSION}"
PR = "r10"

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
    xf86-video-modesetting \
    xf86-video-vesa \
    xf86-video-fbdev \
    xserver-xorg-extension-glx \
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

# Avoid double-start races in QEMU: the classic neutrino.service wrapper can
# trigger a system poweroff on rc=1, while the QEMU X11 launcher already starts
# Neutrino explicitly.
#
# Use IMAGE_PREPROCESS_COMMAND instead of ROOTFS_POSTPROCESS_COMMAND because
# systemd_preset_all in do_image can recreate service symlinks.
IMAGE_PREPROCESS_COMMAND:append = " tuxbox_qemu_disable_neutrino_autostart;"

tuxbox_qemu_disable_neutrino_autostart () {
    rm -f ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/multi-user.target.wants/neutrino.service
}

# Produce wic artifacts for runqemu (ext4 is already enabled by qemu machines).
IMAGE_FSTYPES:append = " wic"
