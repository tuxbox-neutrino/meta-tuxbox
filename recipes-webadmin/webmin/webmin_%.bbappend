SRC_URI:append = " \
	file://0001-software-ipkg-lib-detect-opkg-correctly.patch \
"

WEBMIN_PORT ?= "10000"
WEBMIN_PORT:qemux86-64 = "10001"

PR:append = ".2"

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
}
