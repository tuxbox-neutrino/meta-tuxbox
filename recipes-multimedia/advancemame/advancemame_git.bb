SUMMARY = "AdvanceMame Arcade emulator"
HOMEPAGE = "https://www.advancemame.it/"
SECTION = "emulators"
LICENSE = "GPLv2 & MAME"
LICENSE_FLAGS = "commercial"
LIC_FILES_CHKSUM = "file://COPYING;md5=83348388df42cecffc92b13d7b23899a"

SRC_URI = "git://github.com/amadvance/${BPN}.git;protocol=https;branch=master \
	   file://advmame.rc \
	   file://advmame@.service \
	   file://advmame.cfg \
	   file://advmame.lua \
	   file://advmame_hint.png \
	   file://0001-fix-format-security.patch \
	   file://0002-fix-format-security-blue.patch \
"

SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git"

DEPENDS = "virtual/libsdl2 alsa-lib ncurses freetype zlib expat"

PR = "r6"

inherit autotools-brokensep pkgconfig gettext systemd

SYSTEMD_SERVICE:${PN} = "advmame@.service"
SYSTEMD_AUTO_ENABLE = "disable"

EXTRA_OECONF += "--disable-vc"

do_configure:prepend() {
    # Upstream doesn't ship this and autoreconf won't install it as automake isn't used.
    cp -f $(automake --print-libdir)/install-sh ${S}/
}

do_install:append() {
	install -d ${D}${sysconfdir} -d ${D}${datadir}/tuxbox/neutrino/plugins
	install -m644 ${WORKDIR}/advmame.rc ${D}${sysconfdir}
	install -m644 ${WORKDIR}/advmame.cfg ${D}${datadir}/tuxbox/neutrino/plugins
	install -m644 ${WORKDIR}/advmame.lua ${D}${datadir}/tuxbox/neutrino/plugins
	install -m644 ${WORKDIR}/advmame_hint.png ${D}${datadir}/tuxbox/neutrino/plugins
	if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
		install -d ${D}${systemd_system_unitdir}
		install -m 0644 ${WORKDIR}/advmame@.service ${D}${systemd_system_unitdir}
	fi
}

FILES:${PN} += "${datadir} \
		${sysconfdir} \
		${base_libdir} \
"

FILES:${PN}:append = " ${systemd_system_unitdir}"

FILES:${PN}-doc += "${prefix}/doc/* ${prefix}/man/*"
