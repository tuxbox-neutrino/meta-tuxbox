# Use the tuxbox-neutrino maintained fork to keep flash behavior branding-free
# and aligned with active-slot flashing requirements.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "git://github.com/tuxbox-neutrino/ofgwrite.git;protocol=https;branch=master"
SRC_URI += " \
	file://flash-backend-ofgwrite.sh \
	file://flash-ofgwrite-preflight.sh \
	file://tuxbox-flash-restore.sh \
	file://tuxbox-flash-restore.service \
	file://flash-online-check.sh \
"
# SRCREV inherited from base recipe (${AUTOREV}) — always picks latest
# master of the tuxbox-neutrino fork. Version is derived via gitpkgv
# from the upstream v4.8.0 tag, so no manual pinning is required.

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
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit systemd

do_install:append() {
	install -m 0755 ${S}/ofgwrite_caller ${D}${bindir}/ofgwrite_caller
	install -d ${D}${libexecdir}/tuxbox
	install -m 0755 ${S}/ofgwrite_handoff ${D}${libexecdir}/tuxbox/ofgwrite-handoff
	install -m 0755 ${WORKDIR}/flash-backend-ofgwrite.sh ${D}${libexecdir}/tuxbox/flash-backend-ofgwrite.sh
	install -m 0755 ${WORKDIR}/tuxbox-flash-restore.sh ${D}${libexecdir}/tuxbox/tuxbox-flash-restore.sh
	install -m 0755 ${WORKDIR}/flash-ofgwrite-preflight.sh ${D}${bindir}/flash-backend-preflight
	install -m 0755 ${WORKDIR}/flash-online-check.sh ${D}${bindir}/flash-online-check
	install -d ${D}${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/tuxbox-flash-restore.service ${D}${systemd_system_unitdir}/tuxbox-flash-restore.service
	install -d ${D}${sysconfdir}/tuxbox
	cat > ${D}${sysconfdir}/tuxbox/flash-machine-profile.conf <<EOF
FLASH_MACHINE="${MACHINE}"
FLASH_MACHINEBUILD="${MACHINEBUILD}"
FLASH_MACHINE_DRIVER="${MACHINE_DRIVER}"
FLASH_IMAGE_DIR="${IMAGEDIR}"
FLASH_MTD_KERNEL="${MTD_KERNEL}"
FLASH_MTD_ROOTFS="${MTD_ROOTFS}"
FLASH_KERNEL_FILE="${KERNEL_FILE}"
FLASH_ROOTFS_FILE="${ROOTFS_FILE}"
FLASH_IMAGE_FSTYPES="${IMAGE_FSTYPES}"
FLASH_MACHINE_CAP_OFGWRITE="${TUXBOX_FLASH_MACHINE_CAP_OFGWRITE}"
FLASH_SLOT_COUNT="${TUXBOX_FLASH_SLOT_COUNT}"
FLASH_ROOTFS_SUBDIR_PREFIX="${TUXBOX_FLASH_ROOTFS_SUBDIR_PREFIX}"
FLASH_SLOT_KERNEL_LABEL_PREFIX="${TUXBOX_FLASH_SLOT_KERNEL_LABEL_PREFIX}"
FLASH_SLOT_ROOTFS_LABEL_PREFIX="${TUXBOX_FLASH_SLOT_ROOTFS_LABEL_PREFIX}"
FLASH_SLOT_ROOTFS_SHARED_LABEL="${TUXBOX_FLASH_SLOT_ROOTFS_SHARED_LABEL}"
FLASH_ACTIVE_SLOT_SOURCE="${TUXBOX_FLASH_ACTIVE_SLOT_SOURCE}"
FLASH_SCRIPT_MODE="${TUXBOX_FLASH_SCRIPT_MODE}"
FLASH_BACKUP_BEFORE_ANY_FLASH_DEFAULT="${TUXBOX_FLASH_BACKUP_BEFORE_ANY_FLASH}"
FLASH_OFGWRITE_ALLOW_ACTIVE_SLOT_DEFAULT="${TUXBOX_FLASH_OFGWRITE_ALLOW_ACTIVE_SLOT}"
FLASH_OFGWRITE_ACTIVE_SLOT_REQUIRE_BACKUP_DEFAULT="${TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_REQUIRE_BACKUP}"
FLASH_OFGWRITE_ACTIVE_SLOT_BACKUP_DIR_DEFAULT="${TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_BACKUP_DIR}"
EOF
}

FILES:${PN}:append = " \
	${sysconfdir}/tuxbox/flash-machine-profile.conf \
	${bindir}/flash-backend-preflight \
	${bindir}/flash-online-check \
	${libexecdir}/tuxbox/ofgwrite-handoff \
	${libexecdir}/tuxbox/flash-backend-ofgwrite.sh \
	${libexecdir}/tuxbox/tuxbox-flash-restore.sh \
	${systemd_system_unitdir}/tuxbox-flash-restore.service \
"

SYSTEMD_SERVICE:${PN} = "tuxbox-flash-restore.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

PR:append = ".15"
