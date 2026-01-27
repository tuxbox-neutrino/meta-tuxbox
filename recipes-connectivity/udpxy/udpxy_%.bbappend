FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit systemd

PR:append = ".1"

SYSTEMD_SERVICE:${PN} = "udpxy.service"

CFLAGS:append = " -Wno-stringop-truncation"

do_install:append() {
    install -d ${D}${sysconfdir}/default
    install -m 0644 ${WORKDIR}/udpxy.default ${D}${sysconfdir}/default/udpxy
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/udpxy.service ${D}${systemd_unitdir}/system/udpxy.service
}

do_install:append:sysvinit() {
    rm -f ${D}${systemd_unitdir}/system/udpxy.service
}

FILES:${PN} += " ${sysconfdir}/default/udpxy ${systemd_unitdir}/system/udpxy.service"
