FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
		file://0001-avoid-race-between-systemd-udevd-and-systemd-modules.patch \
		file://service \
		file://wait-online-override.conf \
		"

PR:append = ".6"

do_patch[postfuncs] = ""

do_install:append() {
	install -d ${D}${sbindir}
	install -m 0755 ${WORKDIR}/service ${D}${sbindir}/
	install -d ${D}${sysconfdir}/systemd/system/systemd-networkd-wait-online.service.d
	install -m 0644 ${WORKDIR}/wait-online-override.conf \
		${D}${sysconfdir}/systemd/system/systemd-networkd-wait-online.service.d/override.conf

	# Tuxbox: systemd-udev-trigger.service is a static unit (no [Install]
	# section), so it cannot be enabled via systemd presets. Poky's recipe
	# does not install a sysinit.target.wants/ symlink either, which leaves
	# the coldplug pass disabled and breaks /dev/disk/by-partlabel/ for the
	# stb-startup plugin on first boot. Install the vendor-mandated symlink
	# here so every Tuxbox image triggers the coldplug before sysinit.target.
	install -d ${D}${systemd_unitdir}/system/sysinit.target.wants
	ln -sf ../systemd-udev-trigger.service \
		${D}${systemd_unitdir}/system/sysinit.target.wants/systemd-udev-trigger.service
}

FILES:${PN} += "\
	${sbindir} \
	${sysconfdir}/systemd/system/systemd-networkd-wait-online.service.d/override.conf \
"
