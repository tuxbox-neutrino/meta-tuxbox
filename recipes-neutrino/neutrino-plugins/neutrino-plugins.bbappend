# On these machines, vendor DVB modules already install /usr/bin/turnoff_power.
# Removing the plugin package avoids rootfs file clashes during image creation.
RDEPENDS:${PN}:remove:hd60 = "turnoff-power"
RDEPENDS:${PN}:remove:hd61 = "turnoff-power"
RDEPENDS:${PN}:remove:hd66se = "turnoff-power"

PR:append = ".1"
