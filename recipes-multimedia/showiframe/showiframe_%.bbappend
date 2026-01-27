FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://bootlogo.service"

inherit systemd

PR:append = ".2"

SYSTEMD_SERVICE:${PN} = "bootlogo.service"

do_install:append:systemd() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/bootlogo.service ${D}${systemd_unitdir}/system/
}

FILES:${PN}:append:systemd = " ${systemd_unitdir}/system/bootlogo.service"
