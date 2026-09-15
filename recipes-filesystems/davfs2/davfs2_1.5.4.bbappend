# Bound to the OE-Alliance filename so a base-recipe update requires review.
PV = "1.7.3"
PR:append = ".2"
HOMEPAGE = "https://github.com/alisarctl/davfs2"
LICENSE = "GPL-3.0-or-later & MIT"
LIC_FILES_CHKSUM:append = " file://${WORKDIR}/mount.all.davfs;beginline=3;endline=21;md5=1726f2cbf4a18e16b9863fb05376ae25"

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI:remove = "http://download.savannah.nongnu.org/releases/davfs2/${BP}.tar.gz file://fix-build-with-fno-common.patch"
SRC_URI:append = " https://download-mirror.savannah.gnu.org/releases/davfs2/${BP}.tar.gz \
                  file://mount.all.davfs file://umount.all.davfs \
                  file://mount-list.sh file://davfs2.mount.list file://davfs2.service"

unset SRC_URI[md5sum]
SRC_URI[sha256sum] = "a5368161eb5055651d7e5e8180c1606da95e78c941b6bb8a9286df7923cfcba9"

inherit systemd
SYSTEMD_SERVICE:${PN} = "davfs2.service"
RDEPENDS:${PN} += "bash curl util-linux-findmnt"
RRECOMMENDS:${PN}:remove = "kernel-module-coda"
RRECOMMENDS:${PN}:append = " kernel-module-fuse"
CONFFILES:${PN} += "${sysconfdir}/davfs2/davfs2.mount.list"
FILES:${PN} += "${libexecdir}/davfs2 /mnt/dav"

# The base recipe installs the upstream configuration and volatile directory.
do_install:append () {
    install -d ${D}${sbindir} ${D}${libexecdir}/davfs2 ${D}/mnt/dav
    install -m 0755 ${WORKDIR}/mount.all.davfs ${D}${sbindir}/mount.all.davfs
    install -m 0755 ${WORKDIR}/umount.all.davfs ${D}${sbindir}/umount.all.davfs
    sed -i 's|@LIBEXECDIR@|${libexecdir}|g' ${D}${sbindir}/mount.all.davfs ${D}${sbindir}/umount.all.davfs
    install -m 0644 ${WORKDIR}/mount-list.sh ${D}${libexecdir}/davfs2/mount-list.sh
    install -m 0644 ${WORKDIR}/davfs2.mount.list ${D}${sysconfdir}/davfs2/davfs2.mount.list
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/davfs2.service ${D}${systemd_system_unitdir}/davfs2.service
        sed -i 's|@SBINPATH@|${sbindir}|g' ${D}${systemd_system_unitdir}/davfs2.service
    fi
    sed -i -e 's/# backup_dir      lost+found/backup_dir      backup/' \
           -e 's/# use_compression 0/use_compression 1/' \
           -e 's/# use_locks       1/use_locks       0/' \
           ${D}${sysconfdir}/davfs2/davfs2.conf
}
