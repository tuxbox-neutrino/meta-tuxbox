# Use the tuxbox-neutrino maintained fork to keep flash behavior branding-free
# and aligned with active-slot flashing requirements.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "git://github.com/tuxbox-neutrino/ofgwrite.git;protocol=https;branch=master"
SRC_URI += " file://ofgwrite_caller"
SRCREV = "12830ef0183d96eacda7fc0494022ea63ace8b02"
DEPENDS:append = " openssl"
CFLAGS:append = " -Wno-error=format-security"

do_install:append() {
	install -m 0755 ${WORKDIR}/ofgwrite_caller ${D}${bindir}/ofgwrite_caller
}

PR:append = ".2"
