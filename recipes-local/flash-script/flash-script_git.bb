
DESCRIPTION = "Flash script for ${MACHINE_BRAND}-${IMAGEDIR}"
HOMEPAGE = "https://github.com/tuxbox-neutrino"
MAINTAINER = "Tuxbox-Developers"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=285b6276c3a2d7b9bb2783a4ef5af8d4"

PACKAGE_ARCH = "${MACHINE_ARCH}"

IMAGE_FEATURES += " ${PN} "

SRC_URI = " \
	git://github.com/tuxbox-neutrino/flash-script.git;branch=${TUXBOX_FLASH_SCRIPT_GIT_BRANCH};protocol=https \
	file://flash-ofgwrite-preflight.sh \
	file://flash-dispatch.sh \
	file://flash-backend-script.sh \
	file://flash-backend-ofgwrite.sh \
	file://backup_rootfs.jpg \
	file://update_download.jpg \
	file://update_decompress.jpg \
	file://update_kernel.jpg \
	file://update_rootfs.jpg \
	file://update_done.jpg \
"

PR = "r8"
PV = "0.1+git${SRCPV}"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

RDEPENDS:${PN}:append = "${@bb.utils.contains('TUXBOX_FLASH_BACKEND', 'ofgwrite', ' ofgwrite', '', d)}"

do_install () {
	install -d ${D}${bindir}
	install -m 0755 ${S}/flash ${D}${bindir}/flash-legacy
	install -m 0755 ${WORKDIR}/flash-dispatch.sh ${D}${bindir}/flash
	install -m 0755 ${WORKDIR}/flash-ofgwrite-preflight.sh ${D}${bindir}/flash-backend-preflight
	install -d ${D}${libexecdir}/tuxbox
	install -m 0755 ${WORKDIR}/flash-backend-script.sh ${D}${libexecdir}/tuxbox/flash-backend-script.sh
	install -m 0755 ${WORKDIR}/flash-backend-ofgwrite.sh ${D}${libexecdir}/tuxbox/flash-backend-ofgwrite.sh
	install -d ${D}${sysconfdir}/tuxbox
	cat > ${D}${sysconfdir}/tuxbox/flash-backend.conf <<EOF
FLASH_BACKEND=${TUXBOX_FLASH_BACKEND}
EOF
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
FLASH_SCRIPT_MODE="${TUXBOX_FLASH_SCRIPT_MODE}"
EOF
	install -d ${D}${datadir}/tuxbox/neutrino/icons
	install -m 0644 ${WORKDIR}/backup_rootfs.jpg ${D}${datadir}/tuxbox/neutrino/icons
	install -m 0644 ${WORKDIR}/update_download.jpg ${D}${datadir}/tuxbox/neutrino/icons
	install -m 0644 ${WORKDIR}/update_decompress.jpg ${D}${datadir}/tuxbox/neutrino/icons
	install -m 0644 ${WORKDIR}/update_kernel.jpg ${D}${datadir}/tuxbox/neutrino/icons
	install -m 0644 ${WORKDIR}/update_rootfs.jpg ${D}${datadir}/tuxbox/neutrino/icons
	install -m 0644 ${WORKDIR}/update_done.jpg ${D}${datadir}/tuxbox/neutrino/icons
}

FILES:${PN} += " \
	${sysconfdir}/tuxbox/flash-backend.conf \
	${sysconfdir}/tuxbox/flash-machine-profile.conf \
	${libexecdir}/tuxbox \
	${datadir}/tuxbox/neutrino/icons \
"
