FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://interfaces \
		   file://networking.service \
		   file://networking \
		   file://ifupdown-pre.service \
		   file://99-link-up \
"

PR:append = ".6"

do_install:append() {
	install -d ${D}${systemd_unitdir}/system/multi-user.target.wants/ ${D}${sysconfdir}/network ${D}${sysconfdir}/default
	install -d ${D}${sysconfdir}/network/if-pre-up.d
	install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
	install -d ${D}${sysconfdir}/systemd/system/sockets.target.wants
	install -d ${D}${sysconfdir}/systemd/system/network-online.target.wants
	install -m0644 ${WORKDIR}/interfaces ${D}${sysconfdir}/network/interfaces
	install -m0644 ${WORKDIR}/networking.service ${D}${systemd_unitdir}/system/networking.service
	install -m0644 ${WORKDIR}/ifupdown-pre.service ${D}${systemd_unitdir}/system/ifupdown-pre.service
	install -m0644 ${WORKDIR}/networking ${D}${sysconfdir}/default/networking
	install -m0755 ${WORKDIR}/99-link-up ${D}${sysconfdir}/network/if-pre-up.d/99-link-up
	ln -sf ${systemd_unitdir}/system/networking.service ${D}${systemd_unitdir}/system/multi-user.target.wants/networking.service 

	# ifupdown and systemd-networkd must not manage links in parallel
	rm -f ${D}${sysconfdir}/systemd/system/multi-user.target.wants/systemd-networkd.service
	rm -f ${D}${sysconfdir}/systemd/system/multi-user.target.wants/systemd-resolved.service
	rm -f ${D}${sysconfdir}/systemd/system/sockets.target.wants/systemd-networkd.socket
	rm -f ${D}${sysconfdir}/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service
	rm -f ${D}${sysconfdir}/systemd/system/dbus-org.freedesktop.network1.service
	rm -f ${D}${sysconfdir}/systemd/system/dbus-org.freedesktop.resolve1.service
}

pkg_postinst:${PN}() {
if [ -n "$D" ]; then
	exit 0
fi

if command -v systemctl >/dev/null 2>&1; then
	systemctl disable systemd-networkd.service systemd-networkd.socket \
		systemd-networkd-wait-online.service systemd-resolved.service >/dev/null 2>&1 || true
	systemctl stop systemd-networkd.service systemd-resolved.service >/dev/null 2>&1 || true
	systemctl enable networking.service >/dev/null 2>&1 || true
fi
}

FILES:${PN}:append = " lib/systemd"
CONFFILES:${PN} += " \
	${sysconfdir}/network/interfaces \
	${sysconfdir}/default/networking \
"
