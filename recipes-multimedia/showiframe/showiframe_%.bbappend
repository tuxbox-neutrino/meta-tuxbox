FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://bootlogo.service"

inherit systemd

PR:append = ".1"

SYSTEMD_SERVICE:${PN} = "bootlogo.service"

do_install:append() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/bootlogo.service ${D}${systemd_unitdir}/system/
}

FILES:${PN} += "${systemd_unitdir}/system/bootlogo.service"
