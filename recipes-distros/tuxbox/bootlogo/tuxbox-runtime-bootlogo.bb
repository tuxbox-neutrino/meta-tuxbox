SUMMARY = "Tuxbox runtime bootlogo service"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r0"

SRC_URI = " \
    file://tuxbox-bootlogo \
    file://bootlogo.service \
"

S = "${WORKDIR}"

inherit systemd features_check

REQUIRED_DISTRO_FEATURES = "systemd"

RDEPENDS:${PN} = "showiframe"

SYSTEMD_SERVICE:${PN} = "bootlogo.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/tuxbox-bootlogo ${D}${sbindir}/tuxbox-bootlogo

    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/bootlogo.service ${D}${systemd_unitdir}/system/
}

FILES:${PN} += " \
    ${sbindir}/tuxbox-bootlogo \
    ${systemd_unitdir}/system/bootlogo.service \
"
