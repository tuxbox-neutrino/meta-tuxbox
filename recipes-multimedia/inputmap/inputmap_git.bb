SUMMARY = "Creates virtual input devices from real ones."
HOMEPAGE = "https://github.com/rodrigorc/inputmap.git"
SECTION = "games"
LICENSE = "GPL-3.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=84dcc94da3adb52b53ae4fa38fe49e5d"

DEPENDS = "udev"

SRC_URI = "git://github.com/rodrigorc/inputmap.git;protocol=https;branch=master \
	   file://0001-disable-unsupported-events-by-the-old-kernels.patch \
"

SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git"

PR = "r1"

inherit meson pkgconfig
