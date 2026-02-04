FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
		file://0001-avoid-race-between-systemd-udevd-and-systemd-modules.patch \
		file://10-tuxbox-dhcp.network \
		file://service \
		"

PR:append = ".3"

do_patch[postfuncs] = ""

do_install:append() {
	install -d ${D}${sbindir}
	install -m 0755 ${WORKDIR}/service ${D}${sbindir}/
	install -d ${D}${sysconfdir}/systemd/network
	install -m 0644 ${WORKDIR}/10-tuxbox-dhcp.network \
		${D}${sysconfdir}/systemd/network/10-tuxbox-dhcp.network
}

FILES:${PN} += "\
	${sbindir} \
	${sysconfdir}/systemd/network/10-tuxbox-dhcp.network \
"
