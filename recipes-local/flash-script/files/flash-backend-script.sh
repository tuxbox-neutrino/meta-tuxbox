#!/bin/sh
set -eu

LEGACY_FLASH_BIN="${FLASH_LEGACY_BIN:-/usr/bin/flash-legacy}"
PROFILE_CONF="${FLASH_MACHINE_PROFILE_PATH:-/etc/tuxbox/flash-machine-profile.conf}"
script_mode="${FLASH_SCRIPT_MODE:-legacy}"
ALLOW_ACTIVE_SLOT="${FLASH_ALLOW_ACTIVE_SLOT:-0}"

active_slot_from_cmdline() {
	cmdline="$(cat /proc/cmdline 2>/dev/null || true)"
	case "${cmdline}" in
		*rootsubdir=linuxrootfs[0-9]*)
			slot="${cmdline#*rootsubdir=linuxrootfs}"
			slot="${slot%% *}"
			slot="${slot%%[!0-9]*}"
			printf '%s\n' "${slot}"
			;;
		*)
			printf '%s\n' ""
			;;
	esac
}

ensure_not_active_slot() {
	target_slot="$1"
	active_slot="$(active_slot_from_cmdline)"
	[ -n "${target_slot}" ] || return 0
	[ -n "${active_slot}" ] || return 0
	[ "${ALLOW_ACTIVE_SLOT}" = "1" ] && return 0

	if [ "${target_slot}" = "${active_slot}" ]; then
		printf 'ERROR: refusing to flash active slot %s from live system; set FLASH_ALLOW_ACTIVE_SLOT=1 to override\n' "${target_slot}" >&2
		exit 1
	fi
}

if [ -f "${PROFILE_CONF}" ]; then
	# shellcheck disable=SC1091
	. "${PROFILE_CONF}"
	script_mode="${FLASH_SCRIPT_MODE:-${script_mode}}"
fi

if [ ! -x "${LEGACY_FLASH_BIN}" ]; then
	printf 'ERROR: legacy flash script not executable: %s\n' "${LEGACY_FLASH_BIN}" >&2
	exit 1
fi

slot_arg="${1:-}"
case "${slot_arg}" in
	''|*[!0-9]*)
		# non-slot invocation (e.g. help switch); legacy script handles it
		;;
	*)
		ensure_not_active_slot "${slot_arg}"
		;;
esac

case "${script_mode}" in
	legacy)
		exec "${LEGACY_FLASH_BIN}" "$@"
		;;
	*)
		printf 'ERROR: unsupported FLASH_SCRIPT_MODE "%s"\n' "${script_mode}" >&2
		exit 2
		;;
esac
