TUXBOX_TURNOFF_POWER_DRIVER_BRANDS ?= "abcom airdigital dags gfutures maxytec vuplus"

PR:append = ".1"

do_install:append() {
    if ${@bb.utils.contains_any('BRAND_OEM', d.getVar('TUXBOX_TURNOFF_POWER_DRIVER_BRANDS'), 'true', 'false', d)}; then
        rm -f ${D}${bindir}/turnoff_power
    fi
}
