FILESEXTRAPATHS:prepend := "${THISDIR}/files:${THISDIR}/samba/tuxbox:"

INHERIT:append = " ccache"
CCACHE_DIR:pn-samba = "${TMPDIR}/ccache/${PN}"

PR:append = ".8"

SRC_URI += " \
    file://nmb.service.d/override.conf \
    file://smb.service.d/override.conf \
"

# Package private Samba libraries to avoid QA "installed-vs-shipped"
PACKAGES += "${PN}-private-libs"
FILES:${PN}-private-libs = "${libdir}/samba/*.so*"
RDEPENDS:${PN} += "${PN}-private-libs"
INSANE_SKIP:${PN}-private-libs += "dev-so"

# Replace samba-common postinst/prerm/postrm with POSIX-safe versions
pkg_postinst:${BPN}-common () {
    set +e
    mkdir -p $D/tmp
    grep -v 'pam_smbpass.so' $D/etc/pam.d/common-password > $D/tmp/common-password
    if [ -e $D/tmp/common-password ]; then
        mv $D/tmp/common-password $D/etc/pam.d/common-password
    fi
    echo "password\toptional\t\t\tpam_smbpass.so use_authtok use_first_pass" >> $D/etc/pam.d/common-password

    grep -qE '^kids:' $D/etc/passwd
    if [ $? -ne 0 ]; then
        echo 'kids:x:500:500:Linux User,,,:/media:/bin/false' >> $D/etc/passwd
        echo 'kids:!:16560:0:99999:7:::' >> $D/etc/shadow
    fi

    if [ -e $D/etc/samba/distro/smb-vmc.vmc ]; then
        rm $D/etc/samba/distro/smb-vmc.conf 2>/dev/null || true
        ln -s smb-vmc.vmc $D/etc/samba/distro/smb-vmc.conf
    else
        rm $D/etc/samba/distro/smb-vmc.conf 2>/dev/null || true
        ln -s smb-vmc.samba $D/etc/samba/distro/smb-vmc.conf
    fi

    if [ -z "$D" ]; then
        set +e
        [ -e /etc/samba/private/smbpasswd ] || touch /etc/samba/private/smbpasswd

        grep -qE '^root:' /etc/samba/private/smbpasswd
        if [ $? -ne 0 ]; then
            smbpasswd -Ln root >/dev/null
        fi

        grep -qE '^kids:' /etc/passwd
        if [ $? -ne 0 ]; then
            adduser -h /media -s /bin/false -H -D -u 500 kids 2>/dev/null || adduser -h /media -s /bin/false -H -D kids
        fi

        grep -qE '^kids:' /etc/samba/private/smbpasswd
        if [ $? -ne 0 ]; then
            smbpasswd -Ln kids >/dev/null
        fi
    fi
}

pkg_prerm:${BPN}-common () {
    mkdir -p $D/tmp
    grep -v 'pam_smbpass.so' $D/etc/pam.d/common-password > $D/tmp/common-password
    mv $D/tmp/common-password $D/etc/pam.d/common-password
}

pkg_postrm:${BPN}-common () {
    rm $D/etc/samba/distro/smb-vmc.conf 2>/dev/null || true
}

python __anonymous() {
    bpn = d.getVar("BPN") or "samba"
    key = "pkg_postinst:%s-common" % bpn
    val = d.getVar(key) or ""
    marker = "#!/bin/sh"
    if marker in val:
        d.setVar(key, val.split(marker, 1)[0].rstrip())
}

do_install:append () {
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${sysconfdir}/systemd/system/nmb.service.d
        install -d ${D}${sysconfdir}/systemd/system/smb.service.d
        install -m 0644 ${WORKDIR}/nmb.service.d/override.conf \
            ${D}${sysconfdir}/systemd/system/nmb.service.d/override.conf
        install -m 0644 ${WORKDIR}/smb.service.d/override.conf \
            ${D}${sysconfdir}/systemd/system/smb.service.d/override.conf
    fi
}

FILES:${PN} += " \
    ${sysconfdir}/systemd/system/nmb.service.d \
    ${sysconfdir}/systemd/system/nmb.service.d/override.conf \
    ${sysconfdir}/systemd/system/smb.service.d \
    ${sysconfdir}/systemd/system/smb.service.d/override.conf \
"
