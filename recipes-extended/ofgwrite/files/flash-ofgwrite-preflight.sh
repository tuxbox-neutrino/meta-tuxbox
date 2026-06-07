#!/bin/sh
set -eu

BACKEND_CONF="${FLASH_BACKEND_CONF_PATH:-/etc/tuxbox/flash-backend.conf}"
PROFILE_CONF="${FLASH_MACHINE_PROFILE_PATH:-/etc/tuxbox/flash-machine-profile.conf}"
PROC_CMDLINE_FILE="${FLASH_PROC_CMDLINE_FILE:-/proc/cmdline}"
BOOT_DIR="${FLASH_BOOT_DIR_PATH:-}"
PARTLABEL_DIR="${FLASH_PARTLABEL_DIR_PATH:-/dev/disk/by-partlabel}"

backend_override=""
image_dir=""
target_slot=""
ofgwrite_bin="${OFGWRITE_BIN:-ofgwrite}"
quiet=0
run_nowrite_probe="${FLASH_PREFLIGHT_RUN_OFGWRITE_NOWRITE:-0}"
check_live_layout="${FLASH_PREFLIGHT_CHECK_LAYOUT:-1}"

print_usage() {
	cat <<'EOF'
Usage: flash-backend-preflight [options]

Options:
  --backend <script|ofgwrite>  Override backend (default: value from /etc/tuxbox/flash-backend.conf)
  --image-dir <dir>            Image directory for ofgwrite no-write test
  --slot <n>                   Target slot for STARTUP layout checks
  --ofgwrite-bin <path>        Override ofgwrite executable (default: OFGWRITE_BIN or "ofgwrite")
  --quiet                      Suppress informational output
  -h, --help                   Show this help

Environment overrides:
  FLASH_BACKEND_CONF_PATH      Backend config file (default: /etc/tuxbox/flash-backend.conf)
  FLASH_MACHINE_PROFILE_PATH   Machine profile file (default: /etc/tuxbox/flash-machine-profile.conf)
  FLASH_PROC_CMDLINE_FILE      Kernel cmdline file for live layout checks (default: /proc/cmdline)
  FLASH_BOOT_DIR_PATH          Boot partition mount path for STARTUP layout checks
  FLASH_PARTLABEL_DIR_PATH     Partlabel directory for profile checks (default: /dev/disk/by-partlabel)
  FLASH_PREFLIGHT_CHECK_LAYOUT Set to 0 to skip profile/cmdline layout checks
EOF
}

log() {
	if [ "${quiet}" != "1" ]; then
		printf '%s\n' "$*"
	fi
}

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

cmdline_token_value() {
	key="$1"
	[ -r "${PROC_CMDLINE_FILE}" ] || return 0

	token_value_from_text "${key}" "$(cat "${PROC_CMDLINE_FILE}" 2>/dev/null || true)"
}

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

strip_dev_prefix() {
	value="$1"
	case "${value}" in
		/dev/*)
			printf '%s\n' "${value#/dev/}"
			;;
		*)
			printf '%s\n' "${value}"
			;;
	esac
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

partition_suffix() {
	value="$1"
	suffix="${value##*[!0-9]}"
	printf '%s\n' "${suffix}"
}

partition_prefix() {
	value="$1"
	suffix="$(partition_suffix "${value}")"
	[ -n "${suffix}" ] || return 0
	printf '%s\n' "${value%"${suffix}"}"
}

expected_kernel_for_slot() {
	slot="$1"
	kernel_base="$(strip_dev_prefix "${FLASH_MTD_KERNEL:-}")"
	rootfs_base="$(strip_dev_prefix "${FLASH_MTD_ROOTFS:-}")"
	kernel_label_prefix="${FLASH_SLOT_KERNEL_LABEL_PREFIX:-linuxkernel}"

	[ -n "${kernel_base}" ] || return 0

	if [ -n "${kernel_label_prefix}" ]; then
		if [ "${slot}" = "1" ]; then
			partlabel_kernel="$(resolve_partlabel_device "${kernel_label_prefix}")"
			[ -n "${partlabel_kernel}" ] || partlabel_kernel="$(resolve_partlabel_device "${kernel_label_prefix}1")"
		else
			partlabel_kernel="$(resolve_partlabel_device "${kernel_label_prefix}${slot}")"
		fi
		if [ -n "${partlabel_kernel}" ]; then
			printf '%s\n' "${partlabel_kernel}"
			return 0
		fi
	fi

	kernel_part="$(partition_suffix "${kernel_base}")"
	kernel_prefix="$(partition_prefix "${kernel_base}")"
	case "${slot}${kernel_part}" in
		*[!0-9]*|'')
			printf '%s\n' "${kernel_base}"
			return 0
			;;
	esac

	target_part=$((kernel_part + slot - 1))
	rootfs_part="$(partition_suffix "${rootfs_base}")"
	rootfs_prefix="$(partition_prefix "${rootfs_base}")"
	case "${rootfs_part}" in
		''|*[!0-9]*)
			;;
		*)
			if [ "${slot}" -gt 1 ] && [ "${rootfs_prefix}" = "${kernel_prefix}" ] && [ "${rootfs_part}" -eq $((kernel_part + 1)) ]; then
				target_part=$((target_part + 1))
			fi
			;;
	esac

	printf '%s%s\n' "${kernel_prefix}" "${target_part}"
}

shared_rootfs_device() {
	shared_label="${FLASH_SLOT_ROOTFS_SHARED_LABEL:-userdata}"
	resolve_partlabel_device "${shared_label}"
}

accepted_rootfs_summary() {
	profile_rootfs="$(strip_dev_prefix "${FLASH_MTD_ROOTFS:-}")"
	shared_rootfs="$(shared_rootfs_device)"
	if [ -n "${shared_rootfs}" ] && [ "${shared_rootfs}" != "${profile_rootfs}" ]; then
		printf '%s or shared %s' "${profile_rootfs}" "${shared_rootfs}"
	else
		printf '%s' "${profile_rootfs}"
	fi
}

rootfs_device_allowed() {
	device="$(strip_dev_prefix "$1")"
	profile_rootfs="$(strip_dev_prefix "${FLASH_MTD_ROOTFS:-}")"
	shared_rootfs="$(shared_rootfs_device)"

	[ -n "${device}" ] || return 1
	if [ -n "${profile_rootfs}" ] && [ "${device}" = "${profile_rootfs}" ]; then
		return 0
	fi
	if [ -n "${shared_rootfs}" ] && [ "${device}" = "${shared_rootfs}" ]; then
		return 0
	fi
	return 1
}

validate_bool() {
	name="$1"
	value="$2"
	case "${value}" in
		0|1)
			;;
		*)
			fail "invalid ${name}='${value}' (expected: 0 or 1)"
			;;
	esac
}

check_profile_cmdline_layout() {
	validate_bool "FLASH_PREFLIGHT_CHECK_LAYOUT" "${check_live_layout}"
	[ "${check_live_layout}" = "1" ] || return 0
	[ -r "${PROC_CMDLINE_FILE}" ] || return 0

	profile_rootfs="$(strip_dev_prefix "${FLASH_MTD_ROOTFS:-}")"
	rootfs_prefix="${FLASH_ROOTFS_SUBDIR_PREFIX:-linuxrootfs}"
	active_source="${FLASH_ACTIVE_SLOT_SOURCE:-}"
	root_value="$(cmdline_token_value root)"
	rootsubdir_value="$(cmdline_token_value rootsubdir)"

	case "${rootsubdir_value}" in
		"")
			return 0
			;;
		"${rootfs_prefix}"[0-9]*)
			;;
		*)
			fail "running boot layout uses rootsubdir='${rootsubdir_value}', but machine profile expects prefix '${rootfs_prefix}'"
			;;
	esac

	[ -n "${profile_rootfs}" ] || return 0
	[ -n "${root_value}" ] || return 0

	case "${root_value}" in
		/dev/*)
			runtime_rootfs="$(strip_dev_prefix "${root_value}")"
			;;
		*)
			if [ "${active_source}" = "cmdline" ]; then
				fail "running boot layout uses root='${root_value}', but machine profile expects rootfs device '${profile_rootfs}'"
			fi
			return 0
			;;
	esac

	if ! rootfs_device_allowed "${runtime_rootfs}"; then
		fail "running boot layout root device '${runtime_rootfs}' does not match accepted profile rootfs devices $(accepted_rootfs_summary) (rootsubdir='${rootsubdir_value}'); refusing normal slot flash on an incompatible layout"
	fi

	log "flash preflight ok: live boot layout rootfs ${runtime_rootfs} is accepted (${rootsubdir_value})"
}

check_target_startup_layout() {
	validate_bool "FLASH_PREFLIGHT_CHECK_LAYOUT" "${check_live_layout}"
	[ "${check_live_layout}" = "1" ] || return 0
	[ -n "${target_slot}" ] || return 0

	profile_rootfs="$(strip_dev_prefix "${FLASH_MTD_ROOTFS:-}")"
	rootfs_prefix="${FLASH_ROOTFS_SUBDIR_PREFIX:-linuxrootfs}"
	expected_kernel="$(expected_kernel_for_slot "${target_slot}")"
	[ -n "${profile_rootfs}" ] || return 0

	boot_dir="$(detect_boot_dir)"
	[ -n "${boot_dir}" ] || return 0
	[ -d "${boot_dir}" ] || return 0

	found="0"
	for startup in \
		"${boot_dir}/STARTUP_LINUX_${target_slot}_BOXMODE_1" \
		"${boot_dir}/STARTUP_LINUX_${target_slot}_BOXMODE_12" \
		"${boot_dir}/STARTUP_${target_slot}" \
		"${boot_dir}/STARTUP"; do
		[ -r "${startup}" ] || continue
		case "$(basename "${startup}")" in
			STARTUP)
				[ "${target_slot}" = "$(active_slot_from_rootsubdir "$(cat "${startup}" 2>/dev/null || true)" "${rootfs_prefix}")" ] || continue
				;;
		esac
		found="1"
		startup_text="$(cat "${startup}" 2>/dev/null || true)"
		startup_kernel="$(token_value_from_text kernel "${startup_text}")"
		startup_root="$(token_value_from_text root "${startup_text}")"
		startup_rootsubdir="$(token_value_from_text rootsubdir "${startup_text}")"

		case "${startup_rootsubdir}" in
			"${rootfs_prefix}${target_slot}")
				;;
			"")
				continue
				;;
			*)
				fail "target slot ${target_slot} startup $(basename "${startup}") uses rootsubdir='${startup_rootsubdir}', but profile expects '${rootfs_prefix}${target_slot}'"
				;;
		esac

		case "${startup_root}" in
			/dev/*)
				startup_rootfs="$(strip_dev_prefix "${startup_root}")"
				;;
			"")
				continue
				;;
			*)
				fail "target slot ${target_slot} startup $(basename "${startup}") uses root='${startup_root}', but profile expects rootfs device '${profile_rootfs}'"
				;;
		esac

		if ! rootfs_device_allowed "${startup_rootfs}"; then
			fail "target slot ${target_slot} startup $(basename "${startup}") root device '${startup_rootfs}' does not match accepted profile rootfs devices $(accepted_rootfs_summary); refusing normal slot flash on an incompatible boot layout"
		fi

		case "${startup_kernel}" in
			/dev/*)
				startup_kernel_device="$(strip_dev_prefix "${startup_kernel}")"
				;;
			"")
				startup_kernel_device=""
				;;
			*)
				fail "target slot ${target_slot} startup $(basename "${startup}") uses kernel='${startup_kernel}', but profile expects kernel device '${expected_kernel}'"
				;;
		esac

		if [ -n "${startup_kernel_device}" ] && [ -n "${expected_kernel}" ] && [ "${startup_kernel_device}" != "${expected_kernel}" ]; then
			fail "target slot ${target_slot} startup $(basename "${startup}") kernel device '${startup_kernel_device}' does not match expected profile kernel '${expected_kernel}'; refusing normal slot flash on an incompatible boot layout"
		fi
	done

	if [ "${found}" = "1" ]; then
		log "flash preflight ok: target slot ${target_slot} STARTUP layout matches profile kernel/rootfs contract"
	fi
}

active_slot_from_rootsubdir() {
	text="$1"
	rootfs_prefix="$2"
	value="$(token_value_from_text rootsubdir "${text}")"
	case "${value}" in
		"${rootfs_prefix}"[0-9]*)
			slot="${value#${rootfs_prefix}}"
			slot="${slot%%[!0-9]*}"
			printf '%s\n' "${slot}"
			;;
		*)
			printf '%s\n' ""
			;;
	esac
}

has_kernel_file() {
	dir="$1"
	if [ -n "${FLASH_KERNEL_FILE:-}" ] && [ -f "${dir}/${FLASH_KERNEL_FILE}" ]; then
		return 0
	fi
	if [ -f "${dir}/kernel.bin" ] || [ -f "${dir}/uImage" ]; then
		return 0
	fi
	ls "${dir}"/*kernel*.bin >/dev/null 2>&1
}

has_rootfs_file() {
	dir="$1"
	if [ -n "${FLASH_ROOTFS_FILE:-}" ] && [ -f "${dir}/${FLASH_ROOTFS_FILE}" ]; then
		return 0
	fi
	for name in \
		rootfs.bin \
		root_cfe_auto.bin \
		root_cfe_auto.jffs2 \
		oe_rootfs.bin \
		e2jffs2.img \
		rootfs.tar.bz2 \
		rootfs.ubi \
		rootfs.tar.xz \
		rootfs-one.tar.bz2 \
		rootfs-two.tar.bz2; do
		if [ -f "${dir}/${name}" ]; then
			return 0
		fi
	done
	if ls "${dir}"/*.nfi >/dev/null 2>&1; then
		return 0
	fi
	if ls "${dir}"/*.tar.xz >/dev/null 2>&1; then
		return 0
	fi
	return 1
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--backend)
			[ "$#" -ge 2 ] || fail "missing value for --backend"
			backend_override="$2"
			shift 2
			;;
		--image-dir)
			[ "$#" -ge 2 ] || fail "missing value for --image-dir"
			image_dir="$2"
			shift 2
			;;
		--slot)
			[ "$#" -ge 2 ] || fail "missing value for --slot"
			target_slot="$2"
			shift 2
			;;
		--ofgwrite-bin)
			[ "$#" -ge 2 ] || fail "missing value for --ofgwrite-bin"
			ofgwrite_bin="$2"
			shift 2
			;;
		--quiet)
			quiet=1
			shift
			;;
		-h|--help)
			print_usage
			exit 0
			;;
		*)
			print_usage >&2
			fail "unknown argument: $1"
			;;
	esac
done

backend_from_conf=""
if [ -f "${BACKEND_CONF}" ]; then
	# shellcheck disable=SC1091
	. "${BACKEND_CONF}"
	backend_from_conf="${FLASH_BACKEND:-}"
fi

machine_cap_ofgwrite=""
machine_name=""
if [ -f "${PROFILE_CONF}" ]; then
	# shellcheck disable=SC1091
	. "${PROFILE_CONF}"
	machine_cap_ofgwrite="${FLASH_MACHINE_CAP_OFGWRITE:-}"
	machine_name="${FLASH_MACHINE:-}"
fi

if [ -n "${backend_override}" ]; then
	backend="${backend_override}"
else
	backend="${backend_from_conf:-script}"
fi

case "${backend}" in
	script)
		log "flash preflight ok: backend=script (no ofgwrite checks required)"
		exit 0
		;;
	ofgwrite)
		if [ "${machine_cap_ofgwrite}" = "0" ]; then
			fail "backend=ofgwrite but machine profile marks it unsupported (machine=${machine_name:-unknown})"
		fi

		if ! command -v "${ofgwrite_bin}" >/dev/null 2>&1; then
			fail "backend=ofgwrite but executable not found: ${ofgwrite_bin}"
		fi

		if [ -z "${machine_cap_ofgwrite}" ]; then
			log "warning: no FLASH_MACHINE_CAP_OFGWRITE in profile, running generic checks only"
		fi

		check_profile_cmdline_layout
		check_target_startup_layout

		if [ -z "${image_dir}" ]; then
			help_out="$("${ofgwrite_bin}" -h 2>&1 || true)"
			if [ -z "${help_out}" ]; then
				help_out="$("${ofgwrite_bin}" --help 2>&1 || true)"
			fi
			case "${help_out}" in
				*Usage:\ ofgwrite*|*ofgwrite\ Utility*)
					log "flash preflight ok: backend=ofgwrite binary is callable"
					log "hint: pass --image-dir <dir> to run no-write preflight"
					exit 0
					;;
			esac
			fail "backend=ofgwrite but '${ofgwrite_bin}' did not return recognizable help output"
		fi

		[ -d "${image_dir}" ] || fail "image directory does not exist: ${image_dir}"
		has_kernel_file "${image_dir}" || fail "image directory has no kernel payload: ${image_dir}"
		has_rootfs_file "${image_dir}" || fail "image directory has no rootfs payload: ${image_dir}"

		if [ "${run_nowrite_probe}" != "1" ]; then
			log "flash preflight ok: image payload found (skipping ofgwrite -n probe)"
			log "hint: set FLASH_PREFLIGHT_RUN_OFGWRITE_NOWRITE=1 to enable the ofgwrite no-write probe"
			exit 0
		fi

		log "running ofgwrite no-write preflight: ${ofgwrite_bin} -n -q ${image_dir}"
		if "${ofgwrite_bin}" -n -q "${image_dir}"; then
			log "flash preflight ok: ofgwrite no-write mode succeeded"
			exit 0
		fi
		fail "ofgwrite no-write preflight failed"
		;;
	*)
		printf 'ERROR: invalid backend "%s" (expected: script|ofgwrite)\n' "${backend}" >&2
		exit 2
		;;
esac
