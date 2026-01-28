SUMMARY = "Tuxbox splash bootlogo"
LICENSE = "CLOSED"
PR = "r0"

SRC_URI = "file://splash.bin"

S = "${WORKDIR}"

PACKAGE_ARCH = "${MACHINE}"

inherit deploy

do_install() {
    install -d ${D}${datadir}/bootlogo
    install -m 0644 ${WORKDIR}/splash.bin ${D}${datadir}/bootlogo/splash.bin
}

do_deploy() {
    install -m 0644 ${WORKDIR}/splash.bin ${DEPLOYDIR}/splash.bin
}

addtask deploy before do_package after do_install

FILES:${PN} = "${datadir}/bootlogo/splash.bin"
