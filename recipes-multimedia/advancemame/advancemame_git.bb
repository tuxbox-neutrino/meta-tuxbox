SUMMARY = "AdvanceMame Arcade emulator"
HOMEPAGE = "https://www.advancemame.it/"
SECTION = "emulators"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"

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

PR = "r4"

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
}

do_install:append:systemd() {
	install -d ${D}${systemd_unitdir}/system
	install -m 0644 ${WORKDIR}/advmame@.service ${D}${systemd_unitdir}/system
}

FILES:${PN} += "${datadir} \
		${sysconfdir} \
		${base_libdir} \
"

FILES:${PN}:append = " ${systemd_unitdir}/system"

FILES:${PN}-doc += "${prefix}/doc/* ${prefix}/man/*"
