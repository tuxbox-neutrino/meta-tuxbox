WEBMIN_PORT ?= "10000"
WEBMIN_PORT:qemux86-64 = "10001"

PR:append = ".5"

RRECOMMENDS:${PN}:append = " packagegroup-tuxbox-webmin-minimal"

# This bbappend also lands on the webmin recipe in meta-openembedded, whose
# FILESPATH does not include our directory.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# N_ICONS_DIR for the boot image the login background links to.
require recipes-neutrino/neutrino/neutrino-common-vars.inc

SRC_URI:append = " file://neutrino-logo.png"

do_install:append() {
	if [ -f ${D}${sysconfdir}/webmin/miniserv.conf ]; then
		sed -i -e "s/^port=.*/port=${WEBMIN_PORT}/" \
			${D}${sysconfdir}/webmin/miniserv.conf
	fi

	if [ -f ${D}${sysconfdir}/webmin/config ]; then
		sed -i \
			-e '/^nowebminup=/d' \
			-e '/^noselfwebminup=/d' \
			${D}${sysconfdir}/webmin/config
		echo "nowebminup=1" >> ${D}${sysconfdir}/webmin/config
		echo "noselfwebminup=1" >> ${D}${sysconfdir}/webmin/config
	fi

	if [ -f ${D}${sysconfdir}/webmin/software/config ]; then
		sed -i \
			-e '/^package_system=/d' \
			-e '/^update_system=/d' \
			${D}${sysconfdir}/webmin/software/config
		echo "package_system=ipkg" >> ${D}${sysconfdir}/webmin/software/config
		echo "update_system=ipkg" >> ${D}${sysconfdir}/webmin/software/config
	fi

	# Cronie uses /etc/cron/crontabs in this distro setup.
	if [ -f ${D}${sysconfdir}/webmin/cron/config ]; then
		sed -i -e '/^cron_dir=/d' ${D}${sysconfdir}/webmin/cron/config
		echo "cron_dir=${sysconfdir}/cron/crontabs" >> ${D}${sysconfdir}/webmin/cron/config
	fi

	# Neutrino branding. The Authentic Theme takes these three straight from
	# its config directory and keys them by file name alone: a readable file
	# switches the option on, a missing one switches it off. There is no
	# separate flag to set (settings-logos.cgi, settings-backgrounds.cgi).
	install -d ${D}${sysconfdir}/webmin/authentic-theme
	# 180x90 is the size the theme asks for; it does not scale the file.
	install -m 0644 ${WORKDIR}/neutrino-logo.png \
		${D}${sysconfdir}/webmin/authentic-theme/logo.png
	install -m 0644 ${WORKDIR}/neutrino-logo.png \
		${D}${sysconfdir}/webmin/authentic-theme/logo_welcome.png
	# Login background: follow whatever boot image the neutrino package
	# ships instead of copying it. Without neutrino the link dangles, which
	# only turns the background off - the theme tests the file for -r.
	ln -sf ${N_ICONS_DIR}/start.jpg \
		${D}${sysconfdir}/webmin/authentic-theme/background_content.png
}
