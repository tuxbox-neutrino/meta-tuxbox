# Use the tuxbox-neutrino maintained fork to keep flash behavior branding-free
# and aligned with active-slot flashing requirements.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "git://github.com/tuxbox-neutrino/ofgwrite.git;protocol=https;branch=master \
           file://0001-feat-add-dual-init-system-support-systemd-sysvinit.patch \
           file://0002-fix-skip-init-re-exec-after-pivot_root-on-systemd.patch \
           file://0003-fix-do-not-clean-up-newroot-after-successful-daemoni.patch \
           file://0004-fix-explicitly-stop-GUI-service-before-rescue.target.patch \
           file://0005-fix-use-bind-mount-fallback-when-MS_MOVE-fails-after.patch \
           file://0006-fix-use-fresh-mounts-instead-of-MS_MOVE-on-systemd.patch \
           file://0007-debug-add-per-mount-errno-logging-and-persistent-deb.patch \
           file://0008-debug-show-mount-failure-details-on-framebuffer-and-.patch \
           file://0009-fix-harden-systemd-active-slot-pivot-path.patch \
           "
SRC_URI += " file://ofgwrite_caller"
SRCREV = "12830ef0183d96eacda7fc0494022ea63ace8b02"
PV = "4.x+git1000+${SRCPV}"
PKGV = "4.x+git1000+${GITPKGV}"
DEPENDS:append = " openssl"
CFLAGS:append = " -Wno-error=format-security"

do_install:append() {
	install -m 0755 ${WORKDIR}/ofgwrite_caller ${D}${bindir}/ofgwrite_caller
}

PR:append = ".3"
