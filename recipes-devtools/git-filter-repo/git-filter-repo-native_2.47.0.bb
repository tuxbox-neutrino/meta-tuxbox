SUMMARY = "Git history rewrite tool"
DESCRIPTION = "git-filter-repo rewrites Git history with a fast and flexible filter"
HOMEPAGE = "https://github.com/newren/git-filter-repo"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "\
    file://COPYING;md5=c7162e621636f9077cd9afd23014a064 \
    file://COPYING.mit;md5=b7ac8a79b844e8de331d3ffa3b1c0894 \
"

SRC_URI = "git://github.com/newren/git-filter-repo.git;tag=v2.47.0;protocol=https"
SRCREV = "v2.47.0"
PV = "2.47.0"
PR = "r2"

S = "${WORKDIR}/git"

inherit native

DEPENDS += "python3-native"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/git-filter-repo ${D}${bindir}/git-filter-repo
}

FILES:${PN} = "${bindir}/git-filter-repo"
