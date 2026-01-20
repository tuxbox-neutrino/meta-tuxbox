# Use Tuxbox-Neutrino fork.
SRC_URI = "git://github.com/tuxbox-neutrino/libdvbsi.git;protocol=https;branch=master"

inherit gitpkgv
SRCREV = "${AUTOREV}"
PKGV = "${GITPKGVTAG}"

# Keep feed versions monotonic versus the old r5.x series.
PR = "r6"
PR:append = ".3"
