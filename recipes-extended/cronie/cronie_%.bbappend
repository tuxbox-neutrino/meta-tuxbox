# Keep Cronie and Webmin aligned on the Debian-style cron spool path.
PR:append = ".1"

EXTRA_OECONF:remove = "SPOOL_DIR=${localstatedir}/spool/cron/crontabs"
EXTRA_OECONF:append = " SPOOL_DIR=${sysconfdir}/cron/crontabs"

do_install:append() {
    # Compatibility path for scripts that still expect /var/spool/cron.
    install -d ${D}${localstatedir}/spool
    rm -rf ${D}${localstatedir}/spool/cron
    ln -snf /etc/cron ${D}${localstatedir}/spool/cron
}
