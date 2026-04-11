# Use the tuxbox-neutrino maintained fork to keep flash behavior branding-free
# and aligned with active-slot flashing requirements.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "git://github.com/tuxbox-neutrino/ofgwrite.git;protocol=https;branch=master"
SRCREV = "fa3d998dbe387d9eb1fca3ad9ef7e0680acdf5d7"

# Epoch bump: transition from legacy "4.x+git1000+..." versioning to
# tag-derived PKGV via gitpkgv.  PE=1 ensures the new version sorts
# higher than any previous "4.x+git1000+..." package in the feed.
# PV uses a fixed base (parse-time safe); PKGV is derived at package
# time from git describe against the v4.8.0 upstream tag.
PE = "1"
GITPKGV_PREFIX = "."
GITPKGVTAG_STYLE = "count-short"
PV = "4.8.0+git${SRCPV}"
PKGV = "${GITPKGVTAG}"

DEPENDS:append = " openssl"
RDEPENDS:${PN}:append = " unzip"
CFLAGS:append = " -Wno-error=format-security"

do_install:append() {
	install -m 0755 ${S}/ofgwrite_caller ${D}${bindir}/ofgwrite_caller
}

PR:append = ".9"
