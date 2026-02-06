SUMMARY = "Fork migration helper"
DESCRIPTION = "migit helps migrate forks and rewrite Git history"
HOMEPAGE = "https://github.com/tuxbox-fork-migrations/migit"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRC_URI = "git://github.com/tuxbox-fork-migrations/migit.git;branch=master;protocol=https"
SRCREV = "58fd56c44e7712851f8c8e27abd8885f8b0a5472"
PV = "0.9.41"

S = "${WORKDIR}/git"

inherit native

DEPENDS += "git-native python3-native wget-native git-filter-repo-native"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/migit ${D}${bindir}/migit
}

FILES:${PN} = "${bindir}/migit"
