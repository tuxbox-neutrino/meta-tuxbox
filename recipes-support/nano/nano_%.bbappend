FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

PR:append = ".1"

# Disable alternatives to /bin/editor (we only ship /usr/bin/nano)
ALTERNATIVE:${PN} = ""
ALTERNATIVE_TARGET:${PN} = ""
ALTERNATIVE_LINK_NAME:${PN} = ""

SRC_URI += "file://nanorc"

do_install:append() {
    rm -rf ${D}/home
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/nanorc ${D}${sysconfdir}/nanorc
}

FILES:${PN} += "${sysconfdir}/nanorc"
