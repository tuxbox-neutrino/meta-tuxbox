FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

PR:append = ".2"

SRC_URI:append = " \
    file://0001-mime-use-snprintf-to-fix-format-security-error.patch \
"

CLEANBROKEN = "1"
