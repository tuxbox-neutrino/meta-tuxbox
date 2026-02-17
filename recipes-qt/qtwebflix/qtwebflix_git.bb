SUMMARY = "QtWebflix"
DESCRIPTION = "A viewer for netflix, amazon prime and similar"
LICENSE = "GPL-3.0"
LIC_FILES_CHKSUM = "file://LICENSE.md;md5=84dcc94da3adb52b53ae4fa38fe49e5d"
PR = "r1"

DEPENDS = "qtwebengine qtwidevine"
RDEPENDS:${PN} = "qtwidevine qtwebengine qtflashplayer libnss-mdns"

SRCREV_qtwebflix = "${AUTOREV}"
SRCREV_qtdbusextended = "34971431233dc408553245001148d34a09836df1"
SRCREV_qtmpris = "7251898353f1f5804c9480172ad7df88c4fe7eb6"
SRCREV_FORMAT = "qtwebflix"


SRC_URI = "git://github.com/gort818/qtwebflix.git;protocol=https;name=qtwebflix;branch=master \
           git://github.com/nemomobile/qtdbusextended.git;destsuffix=git/lib/qtdbusextended;branch=master;name=qtdbusextended;protocol=https \
           git://git.merproject.org/mer-core/qtmpris.git;destsuffix=git/lib/qtmpris;branch=master;name=qtmpris;protocol=https \
           file://qtwebflix.service \
           file://browser.service \
           file://ardmediathek.service \
           file://zdfmediathek.service \
           file://artemediathek.service \
           file://3satmediathek.service \
           file://youtube.service \
           file://0001-mainwindow.cpp-spoof-in-ChromeOS-useragent-to-fix-pl.patch \
           "


S = "${WORKDIR}/git"

inherit qmake5 systemd

SYSTEMD_SERVICE:${PN} = "qtwebflix.service browser.service ardmediathek.service \
	zdfmediathek.service artemediathek.service 3satmediathek.service \
	youtube.service"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

do_install() {
	install -d ${D}${bindir} ${D}${systemd_system_unitdir}
	install -m 0755 ${B}/qtwebflix ${D}${bindir}/qtwebflix
	install -m 0644 ${WORKDIR}/qtwebflix.service ${D}${systemd_system_unitdir}/qtwebflix.service
	install -m 0644 ${WORKDIR}/browser.service ${D}${systemd_system_unitdir}/browser.service
	install -m 0644 ${WORKDIR}/ardmediathek.service ${D}${systemd_system_unitdir}/ardmediathek.service
	install -m 0644 ${WORKDIR}/zdfmediathek.service ${D}${systemd_system_unitdir}/zdfmediathek.service
	install -m 0644 ${WORKDIR}/artemediathek.service ${D}${systemd_system_unitdir}/artemediathek.service
	install -m 0644 ${WORKDIR}/3satmediathek.service ${D}${systemd_system_unitdir}/3satmediathek.service
	install -m 0644 ${WORKDIR}/youtube.service ${D}${systemd_system_unitdir}/youtube.service
}


FILES:${PN} = "${bindir}/qtwebflix ${systemd_system_unitdir}"

PATH:prepend = "${STAGING_DIR_NATIVE}${OE_QMAKE_PATH_QT_BINS}:"
