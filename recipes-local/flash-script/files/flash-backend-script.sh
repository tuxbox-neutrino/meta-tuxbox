#!/bin/sh
set -eu

LEGACY_FLASH_BIN="${FLASH_LEGACY_BIN:-/usr/bin/flash-legacy}"
PROFILE_CONF="${FLASH_MACHINE_PROFILE_PATH:-/etc/tuxbox/flash-machine-profile.conf}"
PROC_CMDLINE_FILE="${FLASH_PROC_CMDLINE_FILE:-/proc/cmdline}"
BOOT_DIR="${FLASH_BOOT_DIR_PATH:-}"
PARTLABEL_DIR="${FLASH_PARTLABEL_DIR_PATH:-/dev/disk/by-partlabel}"
DEV_DIR="${FLASH_DEV_DIR:-/dev}"
TARGET_MOUNT_DIR="${FLASH_TARGET_MOUNT_DIR:-/run/tuxbox-flash-target}"
RESOLVE_ONLY="${FLASH_RESOLVE_ONLY:-0}"
script_mode="${FLASH_SCRIPT_MODE:-legacy}"
ALLOW_ACTIVE_SLOT="${FLASH_ALLOW_ACTIVE_SLOT:-0}"
STOP_NEUTRINO_BEFORE_FLASH="${FLASH_STOP_NEUTRINO_BEFORE_FLASH:-}"

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

strip_dev_prefix() {
	value="$1"
	printf '%s\n' "${value#/dev/}"
}

# Keep these helpers behaviourally identical to their namesakes in
# flash-ofgwrite-preflight.sh; both backends must resolve a slot the same way.
token_value_from_text() {
	key="$1"
	text="$2"

	for token in ${text}; do
		token="$(printf '%s' "${token}" | tr -d "'\"")"
		case "${token}" in
			"${key}="*)
				printf '%s\n' "${token#*=}"
				return 0
				;;
		esac
	done

	return 0
}

detect_boot_dir() {
	if [ -n "${BOOT_DIR}" ]; then
		printf '%s\n' "${BOOT_DIR}"
		return 0
	fi

	for dir in /media/boot-mmcblk0p1 /boot /media/boot; do
		if [ -d "${dir}" ]; then
			printf '%s\n' "${dir}"
			return 0
		fi
	done

	return 0
}

resolve_partlabel_device() {
	label="$1"
	[ -n "${label}" ] || return 0
	path="${PARTLABEL_DIR}/${label}"
	[ -e "${path}" ] || return 0
	resolved="$(readlink -f "${path}" 2>/dev/null || true)"
	[ -n "${resolved}" ] || return 0
	case "${resolved}" in
		/dev/*)
			strip_dev_prefix "${resolved}"
			;;
		*)
			basename "${resolved}"
			;;
	esac
}

shared_rootfs_device() {
	resolve_partlabel_device "${FLASH_SLOT_ROOTFS_SHARED_LABEL:-userdata}"
}

rootfs_device_allowed() {
	device="$(strip_dev_prefix "$1")"
	allowed_profile="$(strip_dev_prefix "${FLASH_MTD_ROOTFS:-}")"
	allowed_shared="$(shared_rootfs_device)"

	[ -n "${device}" ] || return 1
	if [ -n "${allowed_profile}" ] && [ "${device}" = "${allowed_profile}" ]; then
		return 0
	fi
	if [ -n "${allowed_shared}" ] && [ "${device}" = "${allowed_shared}" ]; then
		return 0
	fi
	return 1
}

# The STARTUP entry of a slot is the only authoritative statement about where
# that slot's rootfs lives; partlabels can be missing after a failed coldplug.
startup_file_for_slot() {
	slot="$1"
	prefix="${FLASH_ROOTFS_SUBDIR_PREFIX:-linuxrootfs}"

	boot_dir="$(detect_boot_dir)"
	[ -n "${boot_dir}" ] || return 0
	[ -d "${boot_dir}" ] || return 0

	for startup in \
		"${boot_dir}/STARTUP_LINUX_${slot}_BOXMODE_1" \
		"${boot_dir}/STARTUP_LINUX_${slot}_BOXMODE_12" \
		"${boot_dir}/STARTUP_LINUX_${slot}" \
		"${boot_dir}/STARTUP_${slot}" \
		"${boot_dir}/STARTUP"; do
		[ -r "${startup}" ] || continue
		case "${startup}" in
			*/STARTUP)
				subdir="$(token_value_from_text rootsubdir "$(cat "${startup}" 2>/dev/null || true)")"
				[ "${subdir}" = "${prefix}${slot}" ] || continue
				;;
		esac
		printf '%s\n' "${startup}"
		return 0
	done

	return 0
}

mount_target_base() {
	device="$1"
	dev_path="${DEV_DIR}/${device}"

	[ -e "${dev_path}" ] || fail "rootfs device ${dev_path} does not exist"

	mkdir -p "${TARGET_MOUNT_DIR}" 2>/dev/null || fail "cannot create ${TARGET_MOUNT_DIR}"

	# Mount the partition itself rather than reusing an existing mount: a slot
	# booted with rootsubdir= has its subdirectory mounted as /, so /proc/mounts
	# would point at the subdirectory instead of the partition root.
	if ! mount | grep -q " on ${TARGET_MOUNT_DIR} "; then
		mount "${dev_path}" "${TARGET_MOUNT_DIR}" 2>/dev/null || \
			mount -t ext4 "${dev_path}" "${TARGET_MOUNT_DIR}" 2>/dev/null || \
			fail "cannot mount ${dev_path} at ${TARGET_MOUNT_DIR}"
	fi

	FLASH_DESTINATION_BASE="${TARGET_MOUNT_DIR}"
	export FLASH_DESTINATION_BASE
}

ensure_destination_base() {
	slot="$1"
	case "${slot}" in
		''|*[!0-9]*)
			return 0
			;;
	esac

	prefix="${FLASH_ROOTFS_SUBDIR_PREFIX:-linuxrootfs}"
	profile_rootfs="$(strip_dev_prefix "${FLASH_MTD_ROOTFS:-}")"
	shared_rootfs="$(shared_rootfs_device)"

	if [ -n "${FLASH_ROOTFS_TARGET_BASE:-}" ]; then
		printf 'flash-backend: using caller-provided rootfs target base %s\n' "${FLASH_ROOTFS_TARGET_BASE}"
		return 0
	fi

	if [ -n "${FLASH_DESTINATION_BASE:-}" ]; then
		export FLASH_DESTINATION_BASE
		printf 'flash-backend: using caller-provided destination base %s\n' "${FLASH_DESTINATION_BASE}"
		return 0
	fi

	target_device=""
	target_source=""

	startup="$(startup_file_for_slot "${slot}")"
	if [ -n "${startup}" ]; then
		startup_text="$(cat "${startup}" 2>/dev/null || true)"
		startup_root="$(token_value_from_text root "${startup_text}")"
		startup_subdir="$(token_value_from_text rootsubdir "${startup_text}")"

		if [ -n "${startup_subdir}" ] && [ "${startup_subdir}" != "${prefix}${slot}" ]; then
			fail "slot ${slot}: ${startup} declares rootsubdir='${startup_subdir}', expected '${prefix}${slot}'"
		fi

		case "${startup_root}" in
			/dev/*)
				target_device="$(strip_dev_prefix "${startup_root}")"
				target_source="${startup}"
				;;
		esac
	fi

	if [ -z "${target_device}" ] && [ "${slot}" != "1" ] && [ -n "${shared_rootfs}" ]; then
		target_device="${shared_rootfs}"
		target_source="partlabel ${FLASH_SLOT_ROOTFS_SHARED_LABEL:-userdata}"
	fi

	if [ -z "${target_device}" ] && [ -n "${profile_rootfs}" ]; then
		target_device="${profile_rootfs}"
		target_source="profile FLASH_MTD_ROOTFS"
	fi

	if [ -z "${target_device}" ]; then
		fail "slot ${slot}: cannot determine the rootfs partition (no STARTUP entry, no '${FLASH_SLOT_ROOTFS_SHARED_LABEL:-userdata}' partlabel, no FLASH_MTD_ROOTFS)"
	fi

	if ! rootfs_device_allowed "${target_device}"; then
		fail "slot ${slot}: resolved rootfs device '${target_device}' (${target_source}) matches neither the profile rootfs '${profile_rootfs}' nor the shared partition '${shared_rootfs}'; refusing to flash an incompatible layout"
	fi

	# Layouts that keep slot 1 on its own partition (hd51: p3 for slot 1, p7 for
	# the shared slots) must never receive another slot on the slot-1 partition.
	if [ "${slot}" != "1" ] && [ -n "${shared_rootfs}" ] && \
		[ "${shared_rootfs}" != "${profile_rootfs}" ] && \
		[ "${target_device}" = "${profile_rootfs}" ]; then
		fail "slot ${slot} would be written to ${profile_rootfs}, the slot-1 rootfs partition, while the shared slots live on ${shared_rootfs}; refusing"
	fi

	printf 'flash-backend: slot %s rootfs partition /dev/%s (from %s)\n' "${slot}" "${target_device}" "${target_source}"

	if [ "${RESOLVE_ONLY}" = "1" ]; then
		printf 'slot=%s device=/dev/%s source=%s base=%s\n' \
			"${slot}" "${target_device}" "${target_source}" "${TARGET_MOUNT_DIR}"
		return 0
	fi

	mount_target_base "${target_device}"
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
	rootfs_base="${FLASH_MTD_ROOTFS:-}"
	rootfs_base="${rootfs_base#/dev/}"
	case "${rootfs_base}" in
		"${dev_name}"p[0-9]*)
			rootfs_part="${rootfs_base##*p}"
			case "${rootfs_part}" in
				''|*[!0-9]*)
					;;
				*)
					# HD51-style layouts keep p3 for rootfs/userdata and use
					# p2,p4,p5,p6 for the kernel slots.
					if [ "${slot}" -gt 1 ] && [ "${rootfs_part}" -eq $((base_part + 1)) ]; then
						target_part=$((target_part + 1))
					fi
					;;
			esac
			;;
	esac
	target_dev="/dev/${dev_name}p${target_part}"
	[ -e "${target_dev}" ] || return 0

	mkdir -p "${label_base}" 2>/dev/null || true
	ln -sfn "${target_dev}" "${label_path}" 2>/dev/null || true
}

active_slot_from_cmdline() {
	cmdline="$(cat "${PROC_CMDLINE_FILE}" 2>/dev/null || true)"
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
		if [ "${RESOLVE_ONLY}" = "1" ]; then
			# Diagnostic dry run: report the target and touch nothing.
			ensure_destination_base "${slot_arg}"
			exit 0
		fi
		ensure_not_active_slot "${slot_arg}"
		ensure_destination_base "${slot_arg}"
		ensure_kernel_label_for_slot "${slot_arg}"
		ensure_payload_base "$@"
		active_slot="$(active_slot_from_cmdline)"
		if [ -z "${STOP_NEUTRINO_BEFORE_FLASH}" ]; then
			STOP_NEUTRINO_BEFORE_FLASH="1"
			# Inactive-slot flashes do not need to stop the running UI by default.
			if [ -n "${active_slot}" ] && [ "${slot_arg}" != "${active_slot}" ]; then
				STOP_NEUTRINO_BEFORE_FLASH="0"
			fi
		fi
		export FLASH_STOP_NEUTRINO_BEFORE_FLASH="${STOP_NEUTRINO_BEFORE_FLASH}"
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
