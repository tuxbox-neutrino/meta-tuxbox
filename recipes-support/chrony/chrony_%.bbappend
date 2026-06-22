PR:append = ".1"

# Neutrino runtime-adaptive network time.
#
# chrony stays the image-managed time service. So that Neutrino can apply the
# user's configured NTP server WITHOUT rewriting or restarting the main
# chrony.conf, ship a reloadable source directory: Neutrino writes
# /etc/chrony/sources.d/neutrino.sources and runs `chronyc reload sources`.
# Rewriting the image-managed chrony.conf from an app at runtime is fragile and
# makes little sense, since chrony provides a reloadable source dir for exactly
# this.

do_install:append() {
    install -d ${D}${sysconfdir}/chrony/sources.d
    if ! grep -q "^sourcedir ${sysconfdir}/chrony/sources.d" ${D}${sysconfdir}/chrony.conf; then
        echo "" >> ${D}${sysconfdir}/chrony.conf
        echo "# Neutrino-managed additive NTP sources (reloadable)" >> ${D}${sysconfdir}/chrony.conf
        echo "sourcedir ${sysconfdir}/chrony/sources.d" >> ${D}${sysconfdir}/chrony.conf
    fi
}

# ${sysconfdir} is already part of FILES:${PN} in the base recipe, so the new
# directory is packaged with the image.
