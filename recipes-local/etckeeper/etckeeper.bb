LICENSE = "GPL-2.0-or-later & BSD-2-Clause"
LIC_FILES_CHKSUM = "file://debian/copyright;md5=832b090ae3d7f727af067f2256f41d4d"

RDEPENDS:${PN} += "git findutils util-linux-mountpoint perl-module-file-glob glibc-utils"

SRC_URI = "git://github.com/neutrino-hd/etckeeper.git;protocol=https;branch=master \
           file://etckeeper.conf \
"


SRC_URI[md5sum] = "439d65fc487910a30b686788b7c6fc99"
SRC_URI[sha256sum] = "76fd0349ff138b98a4dde831a23a13d3fc6608147ef4fef35ce58ebf48f18f23"

SRCREV = "${AUTOREV}"
PV = "${SRCPV}"
PR = "3"

S = "${WORKDIR}/git"

inherit autotools-brokensep systemd

SYSTEMD_SERVICE:${PN} = "etckeeper.timer"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install:append () {
	install -m 644 ${WORKDIR}/etckeeper.conf ${D}/etc/etckeeper
}

do_install:append:sysvinit () {
	rm -rf ${D}${systemd_unitdir}
}

FILES:${PN}:append = " ${datadir}/bash-completion ${systemd_system_unitdir}/etckeeper.service ${systemd_system_unitdir}/etckeeper.timer"

pkg_postinst_ontarget:${PN} () {
	/usr/bin/etckeeper init
}
