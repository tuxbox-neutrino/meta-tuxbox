

# Some additional lines for /usr/lib/os-release -> /etc/os-release
#
OS_RELEASE_FIELDS:append = " HOME_URL SUPPORT_URL BUG_REPORT_URL VERSION_CODENAME DISTRO_VERSION"

PR:append = ".3"

HOME_URL ?= "https://github.com/tuxbox-neutrino"
SUPPORT_URL ?= "https://wiki.tuxbox-neutrino.org"
BUG_REPORT_URL ?= "https://github.com/tuxbox-neutrino/build-environment/issues"
NAME = "${ID}-Image"
PRETTY_NAME = "${DISTRO_NAME}"
VERSION = "${DISTRO_VERSION}"
