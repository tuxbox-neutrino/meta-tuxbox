SUMMARY = "Out-of-tree TBS USB DVB modules from tbsdtv/linux_media"
SECTION = "kernel/modules"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

inherit module

DEPENDS += "virtual/kernel"

SRC_URI = "git://github.com/tbsdtv/linux_media.git;protocol=https;branch=latest"
SRCREV = "31df469c9e23ec37696dd4e6421cb2e2d8f00f77"

PV = "1.0+git${SRCPV}"
PR = "r0"

S = "${WORKDIR}/git"

# Phase 1 target: bcm7251s based boxes with linux 4.10.12 (hd51/h7 family).
COMPATIBLE_MACHINE = "^(hd51|h7)$"

USB_DIR = "drivers/media/usb/dvb-usb"
FE_DIR = "drivers/media/dvb-frontends"
TUNER_DIR = "drivers/media/tuners"

USB_MODULES = "dvb-usb-tbs5580.ko"
FE_MODULES = "si2183.ko"
TUNER_MODULES = "av201x.ko"

USB_KCONFIG = "CONFIG_DVB_USB=m CONFIG_DVB_USB_TBS5580=m"
FE_KCONFIG = "CONFIG_DVB_SI2183=m"
TUNER_KCONFIG = "CONFIG_MEDIA_TUNER_AV201X=m"

BASE_CFLAGS = "-I${S}/drivers/media/dvb-core -I${S}/drivers/media/dvb-frontends -I${S}/drivers/media/tuners -I${S}/drivers/media/common -I${S}/${USB_DIR}"
USB_EXTRA_CFLAGS = "${BASE_CFLAGS}"
FE_EXTRA_CFLAGS = "${BASE_CFLAGS}"
TUNER_EXTRA_CFLAGS = "${BASE_CFLAGS} -DCONFIG_MEDIA_TUNER_AV201X=1"

do_compile() {
	unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS

	oe_runmake -C "${STAGING_KERNEL_BUILDDIR}" \
		M="${S}/${USB_DIR}" \
		KERNEL_PATH="${STAGING_KERNEL_DIR}" \
		KERNEL_SRC="${STAGING_KERNEL_DIR}" \
		KERNEL_VERSION="${KERNEL_VERSION}" \
		CC="${KERNEL_CC}" LD="${KERNEL_LD}" AR="${KERNEL_AR}" \
		O="${STAGING_KERNEL_BUILDDIR}" \
		KBUILD_EXTRA_SYMBOLS="${KBUILD_EXTRA_SYMBOLS}" \
		${USB_KCONFIG} \
		EXTRA_CFLAGS="${USB_EXTRA_CFLAGS}" \
		${USB_MODULES}

	oe_runmake -C "${STAGING_KERNEL_BUILDDIR}" \
		M="${S}/${FE_DIR}" \
		KERNEL_PATH="${STAGING_KERNEL_DIR}" \
		KERNEL_SRC="${STAGING_KERNEL_DIR}" \
		KERNEL_VERSION="${KERNEL_VERSION}" \
		CC="${KERNEL_CC}" LD="${KERNEL_LD}" AR="${KERNEL_AR}" \
		O="${STAGING_KERNEL_BUILDDIR}" \
		KBUILD_EXTRA_SYMBOLS="${KBUILD_EXTRA_SYMBOLS}" \
		${FE_KCONFIG} \
		EXTRA_CFLAGS="${FE_EXTRA_CFLAGS}" \
		${FE_MODULES}

	oe_runmake -C "${STAGING_KERNEL_BUILDDIR}" \
		M="${S}/${TUNER_DIR}" \
		KERNEL_PATH="${STAGING_KERNEL_DIR}" \
		KERNEL_SRC="${STAGING_KERNEL_DIR}" \
		KERNEL_VERSION="${KERNEL_VERSION}" \
		CC="${KERNEL_CC}" LD="${KERNEL_LD}" AR="${KERNEL_AR}" \
		O="${STAGING_KERNEL_BUILDDIR}" \
		KBUILD_EXTRA_SYMBOLS="${KBUILD_EXTRA_SYMBOLS}" \
		${TUNER_KCONFIG} \
		EXTRA_CFLAGS="${TUNER_EXTRA_CFLAGS}" \
		${TUNER_MODULES}
}

do_install() {
	install -d "${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/tbs-usb"

	for mod in ${USB_MODULES}; do
		install -m 0644 "${S}/${USB_DIR}/${mod}" \
			"${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/tbs-usb/${mod}"
	done

	for mod in ${FE_MODULES}; do
		install -m 0644 "${S}/${FE_DIR}/${mod}" \
			"${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/tbs-usb/${mod}"
	done

	for mod in ${TUNER_MODULES}; do
		install -m 0644 "${S}/${TUNER_DIR}/${mod}" \
			"${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/tbs-usb/${mod}"
	done
}
