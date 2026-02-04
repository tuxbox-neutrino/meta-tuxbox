# Packagegroup: Tuxbox WiFi Firmware
#
# WiFi firmware packages (kernel modules are provided by the machine kernel).

DESCRIPTION = "Tuxbox-OS WiFi firmware packages"
LICENSE = "MIT"
PR = "r2"

inherit packagegroup

PACKAGE_ARCH = "${MACHINE_ARCH}"

RDEPENDS:${PN} = " \
    linux-firmware-carl9170 \
    linux-firmware-ralink \
    linux-firmware-rtl8188 \
    linux-firmware-rtl8192cu \
"
