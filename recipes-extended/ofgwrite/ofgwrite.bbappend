# Use the tuxbox-neutrino maintained fork to keep flash behavior branding-free
# and aligned with active-slot flashing requirements.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "git://github.com/tuxbox-neutrino/ofgwrite.git;protocol=https;branch=master \
           file://ofgwrite_caller"
SRCREV = "fa3d998dbe387d9eb1fca3ad9ef7e0680acdf5d7"

PV = "4.x+git1000+${SRCPV}"
PKGV = "4.x+git1000+${GITPKGV}"

DEPENDS:append = " openssl"
RDEPENDS:${PN}:append = " unzip"
CFLAGS:append = " -Wno-error=format-security"

do_install:append() {
	install -m 0755 ${WORKDIR}/ofgwrite_caller ${D}${bindir}/ofgwrite_caller
}

PR:append = ".6"
