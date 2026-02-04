FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
		file://0001-avoid-race-between-systemd-udevd-and-systemd-modules.patch \
		file://service \
		file://wait-online-override.conf \
		"

PR:append = ".4"

do_patch[postfuncs] = ""

do_install:append() {
	install -d ${D}${sbindir}
	install -m 0755 ${WORKDIR}/service ${D}${sbindir}/
	install -d ${D}${sysconfdir}/systemd/system/systemd-networkd-wait-online.service.d
	install -m 0644 ${WORKDIR}/wait-online-override.conf \
		${D}${sysconfdir}/systemd/system/systemd-networkd-wait-online.service.d/override.conf
}

FILES:${PN} += "\
	${sbindir} \
	${sysconfdir}/systemd/system/systemd-networkd-wait-online.service.d/override.conf \
"
