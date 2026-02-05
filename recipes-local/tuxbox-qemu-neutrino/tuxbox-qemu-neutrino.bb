SUMMARY = "Start Neutrino on X11 for QEMU"
DESCRIPTION = "Systemd unit to start Neutrino with X11 in QEMU images"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r10"

SRC_URI = "\
    file://tuxbox-qemu-neutrino.service \
    file://start-neutrino-x11.sh \
    file://99-qemu-seat.rules \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "tuxbox-qemu-neutrino.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} = "\
    xserver-xorg \
    xinit \
    neutrino \
    kbd \
    udev \
"

do_install() {
    install -d ${D}${bindir} ${D}${systemd_system_unitdir} \
        ${D}${sysconfdir}/udev/rules.d
    install -m 0755 ${WORKDIR}/start-neutrino-x11.sh \
        ${D}${bindir}/tuxbox-qemu-neutrino
    install -m 0644 ${WORKDIR}/tuxbox-qemu-neutrino.service \
        ${D}${systemd_system_unitdir}/tuxbox-qemu-neutrino.service
    install -m 0644 ${WORKDIR}/99-qemu-seat.rules \
        ${D}${sysconfdir}/udev/rules.d/99-qemu-seat.rules
}

FILES:${PN} = "\
    ${bindir}/tuxbox-qemu-neutrino \
    ${systemd_system_unitdir}/tuxbox-qemu-neutrino.service \
    ${sysconfdir}/udev/rules.d/99-qemu-seat.rules \
"
