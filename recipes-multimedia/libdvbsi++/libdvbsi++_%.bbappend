FILESEXTRAPATHS:prepend := "${THISDIR}/libdvbsi++:"

# Use Tuxbox-Neutrino fork
SRC_URI = "git://github.com/tuxbox-neutrino/libdvbsi.git;protocol=https;branch=master"

PR:append = ".1"
