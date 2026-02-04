PR:append = ".1"

do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        if [ -e ${B}/etc/pcscd.service ] && [ -e ${B}/etc/pcscd.socket ]; then
            install -d ${D}${systemd_system_unitdir}
            install -m 0644 ${B}/etc/pcscd.service ${D}${systemd_system_unitdir}/
            install -m 0644 ${B}/etc/pcscd.socket ${D}${systemd_system_unitdir}/
        fi
    fi

    # Avoid empty /etc directory QA warnings.
    rmdir --ignore-fail-on-non-empty ${D}${sysconfdir} 2>/dev/null || true
}
