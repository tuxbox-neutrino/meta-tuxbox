SUMMARY = "Tuxbox runtime bootlogo service"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r1"

require recipes-neutrino/neutrino/neutrino-common-vars.inc

SRC_URI = " \
    file://tuxbox-bootlogo \
    file://bootlogo.service \
"

S = "${WORKDIR}"

inherit systemd features_check

REQUIRED_DISTRO_FEATURES = "systemd"

RDEPENDS:${PN} = "ffmpeg showiframe"

SYSTEMD_SERVICE:${PN} = "bootlogo.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    install -d ${D}${sbindir}
    sed \
        -e 's|@N_ICONS_DIR_VAR@|${N_ICONS_DIR_VAR}|g' \
        -e 's|@N_ICONS_DIR@|${N_ICONS_DIR}|g' \
        ${WORKDIR}/tuxbox-bootlogo > ${D}${sbindir}/tuxbox-bootlogo
    chmod 0755 ${D}${sbindir}/tuxbox-bootlogo

    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/bootlogo.service ${D}${systemd_unitdir}/system/
}

FILES:${PN} += " \
    ${sbindir}/tuxbox-bootlogo \
    ${systemd_unitdir}/system/bootlogo.service \
"
