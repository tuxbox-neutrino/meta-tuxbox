#!/bin/sh
set -eu

LEGACY_FLASH_BIN="${FLASH_LEGACY_BIN:-/usr/bin/flash-legacy}"
PROFILE_CONF="${FLASH_MACHINE_PROFILE_PATH:-/etc/tuxbox/flash-machine-profile.conf}"
script_mode="${FLASH_SCRIPT_MODE:-legacy}"
ALLOW_ACTIVE_SLOT="${FLASH_ALLOW_ACTIVE_SLOT:-0}"

ensure_destination_base() {
	if [ -n "${FLASH_DESTINATION_BASE:-}" ] && [ -d "${FLASH_DESTINATION_BASE}/linuxrootfs1" ]; then
		return 0
	fi

	if [ -d /media/userdata/linuxrootfs1 ]; then
		export FLASH_DESTINATION_BASE="/media/userdata"
		return 0
	fi

	if [ -d /mnt/userdata/linuxrootfs1 ]; then
		export FLASH_DESTINATION_BASE="/mnt/userdata"
		return 0
	fi

	rootfs_device="${FLASH_MTD_ROOTFS:-}"
	rootfs_device="${rootfs_device#/dev/}"
	case "${rootfs_device}" in
		mmcblk*p[0-9]*)
			mkdir -p /media/userdata 2>/dev/null || true
			if ! mount | grep -q "on /media/userdata "; then
				mount -t ext4 "/dev/${rootfs_device}" /media/userdata 2>/dev/null || \
					mount "/dev/${rootfs_device}" /media/userdata 2>/dev/null || true
			fi
			if [ -d /media/userdata/linuxrootfs1 ]; then
				export FLASH_DESTINATION_BASE="/media/userdata"
			fi
			;;
	esac
}

ensure_payload_base() {
	# Keep caller-provided absolute image paths untouched.
	case "${2:-}" in
		/*)
			return 0
			;;
	esac

	# Legacy defaults expect one of these mountpoints.
	if [ -d /media/userdata/service/image ] && [ ! -d /mnt/userdata/service/image ]; then
		mkdir -p /mnt/userdata 2>/dev/null || true
		ln -sfn /media/userdata /mnt/userdata 2>/dev/null || true
	fi
}

ensure_kernel_label_for_slot() {
	slot="$1"
	case "${slot}" in
		''|*[!0-9]*)
			return 0
			;;
	esac

	label_base="${FLASH_DEV_BASE:-/dev/disk/by-partlabel}"
	suffix=""
	[ "${slot}" = "1" ] || suffix="${slot}"
	label_path="${label_base}/linuxkernel${suffix}"

	# Existing machine layout already provides this label.
	[ -e "${label_path}" ] && return 0

	kernel_base="${FLASH_MTD_KERNEL:-}"
	kernel_base="${kernel_base#/dev/}"
	case "${kernel_base}" in
		mmcblk*p[0-9]*)
			dev_name="${kernel_base%p*}"
			base_part="${kernel_base##*p}"
			;;
		*)
			return 0
			;;
	esac

	case "${base_part}" in
		''|*[!0-9]*)
			return 0
			;;
	esac

	target_part=$((base_part + slot - 1))
	target_dev="/dev/${dev_name}p${target_part}"
	[ -e "${target_dev}" ] || return 0

	mkdir -p "${label_base}" 2>/dev/null || true
	ln -sfn "${target_dev}" "${label_path}" 2>/dev/null || true
}

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
	# shellcheck disable=SC1090,SC1091
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
		ensure_destination_base
		ensure_kernel_label_for_slot "${slot_arg}"
		ensure_payload_base "$@"
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
