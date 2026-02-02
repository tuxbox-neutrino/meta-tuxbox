PR:append = ".1"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-make_hash-include-string.h.patch \
"
