FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fontrendering.patch"

PR:append = ".1"
