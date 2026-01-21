DESCRIPTION = "xupnpd - eXtensible UPnP agent"
HOMEPAGE = "http://xupnpd.org"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://../LICENSE;md5=193ff0a3bc8b0d2cb0d1d881586d3388"

DEPENDS += "virtual/lua openssl"
SRCREV = "${AUTOREV}"
SRC_URI = "\
	git://github.com/clark15b/xupnpd.git;branch=master;protocol=https \
	file://xupnpd.patch \
	file://xupnpd-dont-bind-daemon-to-specific-ip-address.patch \
	file://xupnpd.service \
"	

PV = "${SRCPV}"
PR = "r1"

S = "${WORKDIR}/git/src"

inherit base systemd

SYSTEMD_SERVICE:${PN}:systemd = "xupnpd.service"
SYSTEMD_AUTO_ENABLE:systemd = "enable"

# this is very ugly, but the xupnpd makefile is utter crap :-(
SRC = "main.cpp soap.cpp mem.cpp mcast.cpp luaxlib.cpp luaxcore.cpp luajson.cpp luajson_parser.cpp"

CFLAGS += "-I${STAGING_INCDIR}/luajit-2.1"

do_compile () {
	${CC} -O2 -c -o md5.o md5c.c
	${CC} ${CFLAGS} ${LDFLAGS} -DWITH_URANDOM -o xupnpd ${SRC} md5.o -lluajit-5.1 -lm -ldl -lstdc++ -rdynamic -lssl -lcrypto
}


do_install () {
	install -d ${D}${bindir} \
		${D}${datadir}/xupnpd/config \
		${D}${datadir}/xupnpd/playlists \
		${D}${datadir}/xupnpd/plugins
	install -D -m 0755 ${S}/xupnpd ${D}${bindir}/xupnpd
	install -m 0644 ${S}/plugins/xupnpd_stb.lua ${D}${datadir}/xupnpd/plugins
	cp -r ${S}/profiles	${D}${datadir}/xupnpd/
	cp -r ${S}/ui		${D}${datadir}/xupnpd/
	cp -r ${S}/www		${D}${datadir}/xupnpd/
	cp ${S}/*.lua		${D}${datadir}/xupnpd/
}

do_install:append:systemd () {
	install -d ${D}${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/xupnpd.service \
		${D}${systemd_system_unitdir}/xupnpd.service
}

FILES:${PN}:append:systemd = " ${systemd_system_unitdir}"
