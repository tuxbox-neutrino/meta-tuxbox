SUMMARY = "logoview - für CST nevis / apollo"
HOMEPAGE = "https://github.com/coolstreamtech/cst-public-plugins-logoview"
LICENSE = "GPL-2.0"
PRIORITY = "optional"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = "git://github.com/tuxbox-neutrino/plugin-logoview.git;protocol=https;branch=master \
	       file://logoview.service \
"

DEPENDS = "libjpeg-turbo"
SRCREV ?= "${AUTOREV}"
PV = "${SRCPV}"
PR = "2"

S = "${WORKDIR}/git"

inherit systemd

SYSTEMD_SERVICE:${PN} = "logoview.service"

do_compile() { 
}

do_install() {
	install -d ${D}${bindir} ${D}${systemd_system_unitdir}
	install -m 0755 ${S}/bin/logoview.apollo ${D}${bindir}/logoview
	install -m 0644 ${WORKDIR}/logoview.service ${D}${systemd_system_unitdir}/logoview.service
}

FILES:${PN} = "${systemd_system_unitdir} ${bindir}"

SRC_URI[md5sum] = "17e6a3996de2942629dce65db1a701c5"
SRC_URI[sha256sum] = "fbe10d46f61d769f7d92a296102e4e2bd3ee16130f11c5b10a1aae590ea1f5ca"


INSANE_SKIP:${PN}:append = " ldflags already-stripped file-rdeps"
