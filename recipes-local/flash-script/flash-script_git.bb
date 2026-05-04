
DESCRIPTION = "Flash script for ${MACHINE_BRAND}-${IMAGEDIR}"
HOMEPAGE = "https://github.com/tuxbox-neutrino"
MAINTAINER = "Tuxbox-Developers"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=285b6276c3a2d7b9bb2783a4ef5af8d4"

PACKAGE_ARCH = "${MACHINE_ARCH}"

IMAGE_FEATURES += " ${PN} "

inherit gitpkgv

SRC_URI = " \
	git://github.com/tuxbox-neutrino/flash-script.git;branch=${TUXBOX_FLASH_SCRIPT_GIT_BRANCH};protocol=https \
	file://flash-dispatch.sh \
	file://flash-backend-script.sh \
"

PR = "r29"
PV = "0.1+git${SRCPV}"
PKGV = "0.1+git${GITPKGV}"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

RDEPENDS:${PN}:append = "${@bb.utils.contains('TUXBOX_FLASH_BACKEND', 'ofgwrite', ' ofgwrite', '', d)}"

do_install () {
	install -d ${D}${bindir}
	install -m 0755 ${S}/flash ${D}${bindir}/flash-legacy
	install -m 0755 ${WORKDIR}/flash-dispatch.sh ${D}${bindir}/flash
	install -d ${D}${libexecdir}/tuxbox
	install -m 0755 ${WORKDIR}/flash-backend-script.sh ${D}${libexecdir}/tuxbox/flash-backend-script.sh
	install -d ${D}${sysconfdir}/tuxbox
	cat > ${D}${sysconfdir}/tuxbox/flash-backend.conf <<EOF
FLASH_BACKEND=${TUXBOX_FLASH_BACKEND}
EOF
}

FILES:${PN}:append = " \
	${sysconfdir}/tuxbox/flash-backend.conf \
	${libexecdir}/tuxbox \
"
