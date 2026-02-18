# Packagegroup: Tuxbox Webmin Minimal
#
# Curated Webmin subset for STB use-cases.

DESCRIPTION = "Tuxbox-OS minimal Webmin package set for STB devices"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS:${PN} = " \
    webmin \
    webmin-theme-authentic-theme \
    webmin-module-webmin \
    webmin-module-system-status \
    webmin-module-software \
    webmin-module-logviewer \
    webmin-module-filemin \
    webmin-module-net \
    webmin-module-updown \
    webmin-module-time \
    webmin-module-passwd \
    webmin-module-useradmin \
    webmin-module-sshd \
    webmin-module-cron \
"

RRECOMMENDS:${PN} = " \
    webmin-module-init \
    webmin-module-status \
    webmin-module-package-updates \
"
