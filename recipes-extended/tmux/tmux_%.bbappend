FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

PR:append = ".1"

SRC_URI += "file://tmux.sh"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/tmux.sh ${D}${bindir}/tmux.sh
}

FILES:${PN} += "${bindir}/tmux.sh"
