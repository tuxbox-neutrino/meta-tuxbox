SUMMARY = "Generic Makefile installer for Neutrino plugins"
DESCRIPTION = "makeit provides a reusable Makefile for installing Neutrino Lua and shell plugins"
HOMEPAGE = "https://github.com/dbt1/makeit"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=46dd2613e0190d29d4f90059fddd7c18"

SRC_URI = "\
    git://github.com/dbt1/makeit.git;branch=master;protocol=https \
    file://makeit \
"
SRCREV = "de82f7e1c1b424fbd948b6f7598aa216954065d3"
PV = "0.1.0"

S = "${WORKDIR}/git"

inherit native

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${datadir}/makeit ${D}${bindir}
    install -m 0644 ${S}/Makefile ${D}${datadir}/makeit/Makefile
    install -m 0755 ${WORKDIR}/makeit ${D}${bindir}/makeit
}

FILES:${PN} = "\
    ${bindir}/makeit \
    ${datadir}/makeit/Makefile \
"
