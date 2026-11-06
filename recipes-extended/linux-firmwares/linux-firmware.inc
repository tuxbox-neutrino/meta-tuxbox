inherit allarch

PV = "${SRCPV}"
PR = "r1"

SRC_URI = "git://github.com/Toysoft/linux-firmware.git;protocol=https;branch=master \
	   file://license \
"

LICENSE = "proprietary"
LIC_FILES_CHKSUM = "file://${WORKDIR}/license;md5=17a6b3d5436a55985b200c725761907a"

S = "${WORKDIR}/git"

SRCREV = "${AUTOREV}"

PACKAGES = "${PN}"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
FILES:${PN} += "${base_libdir}/firmware"
