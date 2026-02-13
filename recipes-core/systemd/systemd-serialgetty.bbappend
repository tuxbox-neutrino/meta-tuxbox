PR:append = ".2"

python __anonymous() {
    import re

    current = (d.getVar("SERIAL_CONSOLES") or "").strip()

    # Keep explicit settings, but allow replacing the recipe default.
    if current and current != "115200;ttyS0":
        return

    # Prefer the console configured by machine CMDLINE.
    cmdline = d.getVar("CMDLINE") or ""
    match = re.search(r"(?:^|\\s)console=([^,\\s]+)(?:,([0-9]+))?", cmdline)
    if match:
        ttydev = match.group(1)
        baud = match.group(2) or "115200"
        d.setVar("SERIAL_CONSOLES", f"{baud};{ttydev}")
        return

    # Fallback to KERNEL_CONSOLE (e.g. ttyS0,115200n8).
    kconsole = (d.getVar("KERNEL_CONSOLE") or "").strip()
    kmatch = re.match(r"([^,\\s]+)(?:,([0-9]+))?", kconsole)
    if kmatch:
        ttydev = kmatch.group(1)
        baud = kmatch.group(2) or "115200"
        d.setVar("SERIAL_CONSOLES", f"{baud};{ttydev}")
}

do_install() {
    if [ -n "${SERIAL_CONSOLES}" ] ; then
        default_baudrate=$(echo "${SERIAL_CONSOLES}" | sed 's/\;.*//')
        install -d ${D}${systemd_system_unitdir}/
        install -d ${D}${sysconfdir}/systemd/system/getty.target.wants/
        install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants/
        install -m 0644 ${WORKDIR}/serial-getty@.service \
            ${D}${systemd_system_unitdir}/
        sed -i -e "s/\@BAUDRATE\@/$default_baudrate/g" \
            ${D}${systemd_system_unitdir}/serial-getty@.service
        sed -i -e "s/\@TERM\@/${SERIAL_TERM}/g" \
            ${D}${systemd_system_unitdir}/serial-getty@.service

        tmp="${SERIAL_CONSOLES}"
        for entry in $tmp; do
            baudrate=$(echo "$entry" | sed 's/\;.*//')
            ttydev=$(echo "$entry" | sed -e 's/^[0-9]*\;//' -e 's/\;.*//')
            if [ "$baudrate" = "$default_baudrate" ] ; then
                ln -sf ${systemd_system_unitdir}/serial-getty@.service \
                    ${D}${sysconfdir}/systemd/system/getty.target.wants/serial-getty@$ttydev.service
                ln -sf ${systemd_system_unitdir}/serial-getty@.service \
                    ${D}${sysconfdir}/systemd/system/multi-user.target.wants/serial-getty@$ttydev.service
            else
                install -m 0644 ${WORKDIR}/serial-getty@.service \
                    ${D}${systemd_system_unitdir}/serial-getty$baudrate@.service
                sed -i -e "s/\@BAUDRATE\@/$baudrate/g" \
                    ${D}${systemd_system_unitdir}/serial-getty$baudrate@.service
                ln -sf ${systemd_system_unitdir}/serial-getty$baudrate@.service \
                    ${D}${sysconfdir}/systemd/system/getty.target.wants/serial-getty$baudrate@$ttydev.service
                ln -sf ${systemd_system_unitdir}/serial-getty$baudrate@.service \
                    ${D}${sysconfdir}/systemd/system/multi-user.target.wants/serial-getty$baudrate@$ttydev.service
            fi
        done
    fi
}
