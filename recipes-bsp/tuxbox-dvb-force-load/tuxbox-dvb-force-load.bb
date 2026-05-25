SUMMARY = "Force-load proprietary DVB modules with stale modversion CRCs"
DESCRIPTION = "Loads modules from modules-load.d with --force-modversion before systemd-modules-load."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r0"

SRC_URI = " \
    file://tuxbox-dvb-force-load \
    file://tuxbox-dvb-force-load.conf \
    file://tuxbox-dvb-force-load.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "tuxbox-dvb-force-load.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} = "kmod"

do_install() {
    install -d ${D}${sbindir} ${D}${systemd_system_unitdir} ${D}${sysconfdir}/modules-load.d
    install -m 0755 ${WORKDIR}/tuxbox-dvb-force-load \
        ${D}${sbindir}/tuxbox-dvb-force-load
    install -m 0644 ${WORKDIR}/tuxbox-dvb-force-load.conf \
        ${D}${sysconfdir}/modules-load.d/tuxbox-dvb-force-load.conf
    install -m 0644 ${WORKDIR}/tuxbox-dvb-force-load.service \
        ${D}${systemd_system_unitdir}/tuxbox-dvb-force-load.service
}

FILES:${PN} = " \
    ${sbindir}/tuxbox-dvb-force-load \
    ${sysconfdir}/modules-load.d/tuxbox-dvb-force-load.conf \
    ${systemd_system_unitdir}/tuxbox-dvb-force-load.service \
"
