SUMMARY = "QEMU Xorg configuration for Neutrino"
DESCRIPTION = "Provide a minimal Xorg config that works in QEMU"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r1"

SRC_URI = "file://xorg.conf"

S = "${WORKDIR}"

CONFFILES:${PN} = "${sysconfdir}/X11/xorg.conf"

RDEPENDS:${PN} = "xserver-xorg xf86-video-vesa"

do_install() {
    install -d ${D}${sysconfdir}/X11
    install -m 0644 ${WORKDIR}/xorg.conf ${D}${sysconfdir}/X11/xorg.conf
}

FILES:${PN} = "${sysconfdir}/X11/xorg.conf"
