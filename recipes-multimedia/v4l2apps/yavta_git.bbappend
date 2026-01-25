FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://0001-Add-stdout-mode-to-allow-streaming-over-the-network-.patch"

PR:append = ".1"
