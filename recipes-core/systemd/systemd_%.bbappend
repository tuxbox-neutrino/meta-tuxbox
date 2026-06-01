FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
		file://0001-avoid-race-between-systemd-udevd-and-systemd-modules.patch \
		file://service \
		file://wait-online-override.conf \
		file://10-tuxbox-power-key.conf \
		"

PR:append = ".7"

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

	# Tuxbox: hand the power/standby key to the Neutrino GUI instead of letting
	# systemd-logind force a poweroff (default HandlePowerKey=poweroff). Without
	# this, the power key triggers a hard poweroff that bypasses Neutrino's
	# standby logic and the deep-standby RTC-wakeup arming (WORK-130).
	install -d ${D}${sysconfdir}/systemd/logind.conf.d
	install -m 0644 ${WORKDIR}/10-tuxbox-power-key.conf \
		${D}${sysconfdir}/systemd/logind.conf.d/10-tuxbox-power-key.conf
}

FILES:${PN} += "\
	${sbindir} \
	${sysconfdir}/systemd/system/systemd-networkd-wait-online.service.d/override.conf \
	${sysconfdir}/systemd/logind.conf.d/10-tuxbox-power-key.conf \
"
