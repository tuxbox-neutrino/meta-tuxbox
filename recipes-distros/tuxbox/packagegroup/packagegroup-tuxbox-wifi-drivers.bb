# Packagegroup: Tuxbox WiFi Drivers
#
# Optional WiFi kernel modules and firmware packages.

DESCRIPTION = "Tuxbox-OS WiFi driver and firmware packages"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

PACKAGE_ARCH = "${MACHINE_ARCH}"

RRECOMMENDS:${PN} = " \
    kernel-module-carl9170 \
    kernel-module-rt2800usb \
    kernel-module-rtl8192cu \
    kernel-module-zd1211rw \
    linux-firmware-carl9170 \
    linux-firmware-ralink \
    linux-firmware-rtl8192cu \
"
