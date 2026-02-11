#!/bin/sh
set -eu

BACKEND_CONF="${FLASH_BACKEND_CONF_PATH:-/etc/tuxbox/flash-backend.conf}"
SCRIPT_HANDLER="${FLASH_BACKEND_SCRIPT_HANDLER:-/usr/libexec/tuxbox/flash-backend-script.sh}"
OFGWRITE_HANDLER="${FLASH_BACKEND_OFGWRITE_HANDLER:-/usr/libexec/tuxbox/flash-backend-ofgwrite.sh}"

backend="script"
backend_override="${FLASH_BACKEND:-}"
if [ -f "${BACKEND_CONF}" ]; then
	# shellcheck disable=SC1091
	. "${BACKEND_CONF}"
	backend="${FLASH_BACKEND:-script}"
fi
if [ -n "${backend_override}" ]; then
	backend="${backend_override}"
fi

case "${backend}" in
	script)
		handler="${SCRIPT_HANDLER}"
		;;
	ofgwrite)
		handler="${OFGWRITE_HANDLER}"
		;;
	*)
		printf 'ERROR: Unsupported FLASH_BACKEND "%s" in %s\n' "${backend}" "${BACKEND_CONF}" >&2
		exit 2
		;;
esac

if [ ! -x "${handler}" ]; then
	printf 'ERROR: Flash backend handler not executable: %s\n' "${handler}" >&2
	exit 1
fi

exec "${handler}" "$@"
