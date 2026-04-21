SUMMARY = "Manifest-first image portal service for Neutrino online flash"
DESCRIPTION = "JSON catalog API, secure download redirect endpoint and NI legacy adapter"
HOMEPAGE = "https://github.com/tuxbox-neutrino/online-portal-service"
MAINTAINER = "Tuxbox-Developers"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=087d23281c3a088db65b90c061d4b049"

FILESEXTRAPATHS:prepend := "${THISDIR}/online-portal-service/files:"

PR = "r2"
PV = "0.1+git${SRCPV}"
PKGV = "0.1+git${GITPKGV}"

inherit gitpkgv systemd useradd

SRC_URI = " \
    git://github.com/tuxbox-neutrino/online-portal-service.git;protocol=https;branch=master \
    file://image-portal.conf \
    file://config.php \
    file://image-portal-refresh-catalog \
    file://image-portal-catalog-refresh.service \
    file://image-portal-catalog-refresh.timer \
    file://nginx-image-portal.conf \
"

SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

RDEPENDS:${PN} = "php-cli"
RRECOMMENDS:${PN} = "nginx php-fpm"

SYSTEMD_SERVICE:${PN} = "image-portal-catalog-refresh.timer"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM:${PN} = "--system image-portal"
USERADD_PARAM:${PN} = "--system --no-create-home --home /nonexistent --shell /sbin/nologin --gid image-portal image-portal"

do_install() {
    install -d ${D}${datadir}/image-portal
    cp -R --no-preserve=ownership,mode ${S}/public ${D}${datadir}/image-portal/
    cp -R --no-preserve=ownership,mode ${S}/src ${D}${datadir}/image-portal/
    cp -R --no-preserve=ownership,mode ${S}/tools ${D}${datadir}/image-portal/
    install -d ${D}${datadir}/image-portal/config
    install -m 0644 ${S}/config/config.php ${D}${datadir}/image-portal/config/config.php.dist

    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/image-portal.conf ${D}${sysconfdir}/image-portal.conf
    install -d ${D}${sysconfdir}/image-portal
    install -m 0644 ${WORKDIR}/config.php ${D}${sysconfdir}/image-portal/config.php

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/image-portal-refresh-catalog ${D}${bindir}/image-portal-refresh-catalog

    install -d ${D}${sysconfdir}/nginx/conf.d
    install -m 0644 ${WORKDIR}/nginx-image-portal.conf ${D}${sysconfdir}/nginx/conf.d/image-portal.conf

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/image-portal-catalog-refresh.service ${D}${systemd_system_unitdir}/
        install -m 0644 ${WORKDIR}/image-portal-catalog-refresh.timer ${D}${systemd_system_unitdir}/
    fi
}

FILES:${PN} += " \
    ${datadir}/image-portal \
    ${sysconfdir}/image-portal.conf \
    ${sysconfdir}/image-portal/config.php \
    ${bindir}/image-portal-refresh-catalog \
    ${sysconfdir}/nginx/conf.d/image-portal.conf \
"

FILES:${PN}:append = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', ' ${systemd_system_unitdir}/image-portal-catalog-refresh.service ${systemd_system_unitdir}/image-portal-catalog-refresh.timer', '', d)}"

CONFFILES:${PN} += " \
    ${sysconfdir}/image-portal.conf \
    ${sysconfdir}/image-portal/config.php \
"
