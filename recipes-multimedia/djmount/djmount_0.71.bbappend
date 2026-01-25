FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://0001-djmount-fixed-crash.patch \
    file://0002-djmount-fixed-crash-when-using-UTF-8-charset.patch \
    file://0003-djmount-fix-hang-with-asset-upnp.patch \
    file://0004-djmount-fix-incorrect-range-when-retrieving-content-.patch \
    file://0015-djmount-fix-compiler-warnings.patch \
    file://0016-djmount-codeset.patch \
"

PR:append = ".1"
