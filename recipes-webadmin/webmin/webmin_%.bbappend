WEBMIN_PORT ?= "10000"
WEBMIN_PORT:qemux86-64 = "10001"

PR:append = ".1"

do_install:append() {
	if [ -f ${D}${sysconfdir}/webmin/miniserv.conf ]; then
		sed -i -e "s/^port=.*/port=${WEBMIN_PORT}/" \
			${D}${sysconfdir}/webmin/miniserv.conf
	fi
}
