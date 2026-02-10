#!/bin/sh
set -eu

LEGACY_FLASH_BIN="${FLASH_LEGACY_BIN:-/usr/bin/flash-legacy}"
PROFILE_CONF="${FLASH_MACHINE_PROFILE_PATH:-/etc/tuxbox/flash-machine-profile.conf}"
script_mode="${FLASH_SCRIPT_MODE:-legacy}"

if [ -f "${PROFILE_CONF}" ]; then
	# shellcheck disable=SC1091
	. "${PROFILE_CONF}"
	script_mode="${FLASH_SCRIPT_MODE:-${script_mode}}"
fi

if [ ! -x "${LEGACY_FLASH_BIN}" ]; then
	printf 'ERROR: legacy flash script not executable: %s\n' "${LEGACY_FLASH_BIN}" >&2
	exit 1
fi

case "${script_mode}" in
	legacy)
		exec "${LEGACY_FLASH_BIN}" "$@"
		;;
	*)
		printf 'ERROR: unsupported FLASH_SCRIPT_MODE "%s"\n' "${script_mode}" >&2
		exit 2
		;;
esac
