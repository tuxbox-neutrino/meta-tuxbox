DESCRIPTION = "Firmware for TBS 5580"
LICENSE = "CLOSED"
require conf/license/license-close.inc

SRC_URI = "https://www.tbsdtv.com/download/document/linux/tbs-tuner-firmwares_v1.0.tar.bz2"
SRC_URI[sha256sum] = "972f3e26c88c51252655f028e79abb3c53f085cfb96551f86a8a678c963e2d4e"

S = "${WORKDIR}"

PACKAGES = "${PN}"
FILES:${PN} += "${nonarch_base_libdir}/firmware"

inherit allarch

do_install() {
	install -d ${D}${nonarch_base_libdir}/firmware
	install -m 0644 ${WORKDIR}/dvb-usb-id5580.fw ${D}${nonarch_base_libdir}/firmware/
}
