SUMMARY = "Samsung Configuration for LCD4Linux"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"


include lcd4linux.inc tuxbox.inc

RDEPENDS:${PN} = "lcd4linux"

SRC_URI = "git://github.com/horsti58/SamsungLCD4Linux;protocol=https;branch=master \
"
PATCHTOOL = "git"

SRCREV = "${AUTOREV}"
PV = "${SRCPV}"
PR = "r3"


do_configure() {
	sed -i "s|\/var\/lcd|\/usr\/share\/lcd|" ${S}/etc/lcd4linux.conf
	# Neutrino writes the line of the later forecast (2 today, 3 tomorrow)
	# to /tmp/lcd/weather_later, decided in the box's time zone; lcd4linux
	# keeps the zone it was started with, so its own clock is not asked.
	sed -i -E "s#strftime\('%H', *time\(\)\) *< *16 *\? *2 *: *3#file::readline('/tmp/lcd/weather_later', 1)#g" ${S}/etc/lcd4linux.conf
	if grep -q -E "strftime\('%H', *time\(\)\) *[<>]" ${S}/etc/lcd4linux.conf || \
	   [ "$(grep -c "/tmp/lcd/weather_later" ${S}/etc/lcd4linux.conf)" -ne 2 ]; then
		bbfatal "lcd4linux.conf: the later forecast is no longer chosen as expected, adjust the replacement"
	fi
}

do_install() {
	install -d ${D}/usr
	cp -rf ${S}/etc ${D}
	cp -rf ${S}/share ${D}/usr
	[ -d ${S}/var/lcd ] && cp -rf ${S}/var/lcd/* ${D}/usr/share/lcd/
	chmod 600 ${D}/${sysconfdir}/lcd4linux.conf
}

FILES:${PN} += "/usr \
		/etc \
" 
