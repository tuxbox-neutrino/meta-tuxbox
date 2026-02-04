# Packagegroup: Tuxbox WiFi
#
# WiFi support and wireless drivers

DESCRIPTION = "Tuxbox-OS WiFi support packages"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

RDEPENDS:${PN} = " \
    wpa-supplicant \
    iw \
    wireless-tools \
    bluez5 \
"
