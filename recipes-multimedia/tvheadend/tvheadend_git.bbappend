FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PR:append = ".5"

SRC_URI:append = " file://tvheadend.service"

DEPENDS:append = " ffmpeg libopus nasm libvpx"

EXTRA_OECONF:append = " \
    --enable-nvenc \
    --enable-cardclient \
    --enable-mmal \
    --enable-ffmpeg \
    --enable-inotify \
    --enable-pcre2 \
    --enable-uriparser \
    --enable-tvhcsa \
    --enable-bundle \
    --enable-dvbcsa \
    --enable-kqueue \
    --enable-libvpx \
    --enable-libopus \
    --enable-ddci \
"

inherit systemd
SYSTEMD_SERVICE:${PN}:systemd = "tvheadend.service"

do_install:append:systemd() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/tvheadend.service \
        ${D}${systemd_system_unitdir}/tvheadend.service
}

FILES:${PN}:append:systemd = " ${systemd_system_unitdir}"

pkg_preinst:${PN} () {
    #!/bin/sh
    if [ -z "$D" ] && command -v systemctl >/dev/null 2>&1; then
        systemctl stop tvheadend || true
    fi
}

pkg_postinst:${PN} () {
    #!/bin/sh
    if [ -n "$D" ]; then
        exit 1
    fi

    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload
    fi
}
