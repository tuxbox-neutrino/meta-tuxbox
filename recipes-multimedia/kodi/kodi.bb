SUMMARY = "Systemd service for kodi startup"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PV = "1.0"
PR = "r1"

inherit systemd

SRC_URI = "file://kodi.service \
	   file://start_kodi.lua \
	   file://start_kodi.cfg \
	   file://start_kodi_hint.png \
"

SYSTEMD_SERVICE:${PN} = "kodi.service"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

do_install() {
	install -d ${D}${systemd_system_unitdir} ${D}${datadir}/tuxbox/neutrino/plugins
	install -m 0644 ${WORKDIR}/kodi.service ${D}${systemd_system_unitdir}/kodi.service
	install -m 0644 ${WORKDIR}/start_kodi* ${D}${datadir}/tuxbox/neutrino/plugins 
}

FILES:${PN} = "${systemd_system_unitdir} ${datadir}/tuxbox/neutrino/plugins"

RDEPENDS:${PN} += "virtual/kodi steam-devices"
