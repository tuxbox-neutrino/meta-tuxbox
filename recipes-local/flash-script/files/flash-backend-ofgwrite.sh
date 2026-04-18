#!/bin/sh
set -eu

BACKEND_PREFLIGHT_BIN="${FLASH_BACKEND_PREFLIGHT_BIN:-/usr/bin/flash-backend-preflight}"
OFGWRITE_BIN="${FLASH_BACKEND_OFGWRITE_BIN:-ofgwrite}"
PROFILE_CONF="${FLASH_MACHINE_PROFILE_PATH:-/etc/tuxbox/flash-machine-profile.conf}"
PROC_CMDLINE_FILE="${FLASH_PROC_CMDLINE_FILE:-/proc/cmdline}"
FLASH_VERSION_FILE="${FLASH_VERSION_FILE_PATH:-/etc/image-version}"
CURL_BIN="${FLASH_CURL_BIN:-curl}"
UNZIP_BIN="${FLASH_UNZIP_BIN:-unzip}"
IMAGE_BASE_OVERRIDE="${FLASH_IMAGE_BASE_OVERRIDE:-}"
ALLOW_ACTIVE_SLOT="${FLASH_ALLOW_ACTIVE_SLOT:-}"
ACTIVE_SLOT_REQUIRE_BACKUP="${FLASH_ACTIVE_SLOT_REQUIRE_BACKUP:-}"
ACTIVE_SLOT_BACKUP_DIR="${FLASH_ACTIVE_SLOT_BACKUP_DIR:-}"
ACTIVE_SLOT_BACKUP_NAME_PREFIX="${FLASH_ACTIVE_SLOT_BACKUP_NAME_PREFIX:-settings-before-flash-slot}"
BACKUP_BIN="${FLASH_BACKUP_BIN:-/usr/bin/backup.sh}"
STOP_NEUTRINO_BEFORE_FLASH="${FLASH_STOP_NEUTRINO_BEFORE_FLASH:-1}"
ACTIVE_SLOT_SYSTEMD_UNIT_NAME="${FLASH_ACTIVE_SLOT_SYSTEMD_UNIT_NAME:-tuxbox-active-flash-ofgwrite.service}"
TRACE_ENABLE="${FLASH_BACKEND_TRACE_ENABLE:-1}"
TRACE_FILE="${FLASH_BACKEND_TRACE_FILE:-/var/log/tuxbox/flash-backend-ofgwrite.log}"
TRACE_MAX_LIST_LINES="${FLASH_BACKEND_TRACE_MAX_LIST_LINES:-40}"
TRACE_READY="0"
TARGET_IS_ACTIVE_SLOT="0"
ACTIVE_SLOT=""

if [ -f "${PROFILE_CONF}" ]; then
	# shellcheck disable=SC1091
	. "${PROFILE_CONF}"
fi

if [ -z "${ALLOW_ACTIVE_SLOT}" ]; then
	ALLOW_ACTIVE_SLOT="${FLASH_OFGWRITE_ALLOW_ACTIVE_SLOT_DEFAULT:-0}"
fi
if [ -z "${ACTIVE_SLOT_REQUIRE_BACKUP}" ]; then
	ACTIVE_SLOT_REQUIRE_BACKUP="${FLASH_OFGWRITE_ACTIVE_SLOT_REQUIRE_BACKUP_DEFAULT:-1}"
fi
if [ -z "${ACTIVE_SLOT_BACKUP_DIR}" ]; then
	ACTIVE_SLOT_BACKUP_DIR="${FLASH_OFGWRITE_ACTIVE_SLOT_BACKUP_DIR_DEFAULT:-/media/hdd/backup/flash-active-slot}"
fi

print_usage() {
	cat <<'EOF'
Usage: flash <slot> [<image-dir>|restore|force] [force]

ofgwrite backend mode:
  slot      positive integer multiboot slot number
  image-dir absolute path to unpacked image directory
  restore   load image from default backup location
  force     in arg2: force download from feed, in arg3: pass -f to ofgwrite

Examples:
  flash 2
  flash 2 force
  flash 2 restore
  flash 2 /media/usb/images/zgemmah7
  flash 3 /media/hdd/images/hd51 force
EOF
}

log() {
	printf '%s\n' "$*"
}

trace_init() {
	[ "${TRACE_ENABLE}" = "1" ] || return 0
	case "${TRACE_FILE}" in
		/*)
			;;
		*)
			TRACE_ENABLE="0"
			return 0
			;;
	esac

	trace_dir="${TRACE_FILE%/*}"
	if [ -z "${trace_dir}" ] || [ "${trace_dir}" = "${TRACE_FILE}" ]; then
		trace_dir="/"
	fi

	if mkdir -p "${trace_dir}" >/dev/null 2>&1 && touch "${TRACE_FILE}" >/dev/null 2>&1; then
		TRACE_READY="1"
	fi
}

trace() {
	[ "${TRACE_ENABLE}" = "1" ] || return 0
	[ "${TRACE_READY}" = "1" ] || return 0
	ts="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || true)"
	printf '%s %s\n' "${ts}" "$*" >>"${TRACE_FILE}" 2>/dev/null || true
}

trace_runtime_snapshot() {
	trace "snapshot begin"
	if [ -r "${PROC_CMDLINE_FILE}" ]; then
		trace "cmdline=$(tr -d '\n' <"${PROC_CMDLINE_FILE}" 2>/dev/null || true)"
	fi
	if [ -r /proc/mounts ]; then
		grep -E '/newroot|/media/|mmcblk|linuxrootfs| / ' /proc/mounts 2>/dev/null | \
			while IFS= read -r line; do
				trace "mount: ${line}"
			done
	fi
	trace "snapshot end"
}

trace_image_payload() {
	dir="$1"
	trace "image payload dir=${dir}"
	if [ ! -d "${dir}" ]; then
		trace "image payload dir missing"
		return 0
	fi

	ls -la "${dir}" 2>/dev/null | sed -n "1,${TRACE_MAX_LIST_LINES}p" | while IFS= read -r line; do
		trace "ls: ${line}"
	done

	if command -v find >/dev/null 2>&1; then
		find "${dir}" -maxdepth 1 -type f 2>/dev/null | while IFS= read -r file; do
			size_bytes="$(wc -c <"${file}" 2>/dev/null || true)"
			md5_value=""
			if command -v md5sum >/dev/null 2>&1; then
				md5_value="$(md5sum "${file}" 2>/dev/null | awk '{print $1}' || true)"
			fi
			trace "file: $(basename "${file}") size=${size_bytes} md5=${md5_value}"
		done
	fi
}

fail() {
	trace "ERROR: $*"
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
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

resolve_executable() {
	cmd="$1"
	if [ -x "${cmd}" ]; then
		printf '%s\n' "${cmd}"
		return 0
	fi
	if command -v "${cmd}" >/dev/null 2>&1; then
		command -v "${cmd}"
		return 0
	fi
	return 1
}

cleanup_stale_ofgwrite_runtime() {
	for p in /proc/[0-9]*; do
		exe_path="$(readlink -f "${p}/exe" 2>/dev/null || true)"
		case "${exe_path}" in
			/newroot/ofgwrite_bin)
				kill -9 "${p##*/}" >/dev/null 2>&1 || true
				;;
		esac
	done

	while grep -q " /newroot " /proc/mounts 2>/dev/null; do
		umount -l /newroot >/dev/null 2>&1 || true
		sleep 0.2
	done

	rm -rf /newroot >/dev/null 2>&1 || true
}

verify_active_slot_runtime_prereqs() {
	[ "${TARGET_IS_ACTIVE_SLOT}" = "1" ] || return 0

	if ! command -v ps >/dev/null 2>&1 || ! ps >/dev/null 2>&1; then
		fail "active-slot flashing requires a working 'ps' binary on the running image"
	fi

	if command -v pkill >/dev/null 2>&1 && ! pkill -V >/dev/null 2>&1; then
		fail "active-slot flashing requires a working 'pkill' binary on the running image"
	fi
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
	ACTIVE_SLOT="$(active_slot_from_cmdline)"
	TARGET_IS_ACTIVE_SLOT="0"

	[ -n "${ACTIVE_SLOT}" ] || return 0

	if [ "${target_slot}" = "${ACTIVE_SLOT}" ]; then
		TARGET_IS_ACTIVE_SLOT="1"
		trace "target slot ${target_slot} is active slot"
		[ "${ALLOW_ACTIVE_SLOT}" = "1" ] && return 0
		fail "refusing to flash active slot ${target_slot} from live system; set FLASH_ALLOW_ACTIVE_SLOT=1 to override"
	fi
}

stop_frontend_runtime() {
	# Active-slot flash always needs neutrino stopped before pivot_root
	if [ "${TARGET_IS_ACTIVE_SLOT}" = "1" ]; then
		stop_required="1"
	else
		stop_required="${STOP_NEUTRINO_BEFORE_FLASH}"
	fi
	[ "${stop_required}" = "1" ] || return 0

	if command -v systemctl >/dev/null 2>&1; then
		systemctl stop neutrino.service >/dev/null 2>&1 || true
		systemctl stop neutrino >/dev/null 2>&1 || true
	fi

	if command -v pkill >/dev/null 2>&1; then
		pkill -x neutrino >/dev/null 2>&1 || true
	elif command -v killall >/dev/null 2>&1; then
		killall neutrino >/dev/null 2>&1 || true
	fi

	sync
}

is_systemd_runtime() {
	command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]
}

start_active_slot_systemd_flash() {
	[ "${TARGET_IS_ACTIVE_SLOT}" = "1" ] || return 1
	is_systemd_runtime || return 1

	unit_name="${ACTIVE_SLOT_SYSTEMD_UNIT_NAME}"
	case "${unit_name}" in
		*.service)
			;;
		*)
			unit_name="${unit_name}.service"
			;;
	esac
	case "${unit_name}" in
		*/*)
			fail "FLASH_ACTIVE_SLOT_SYSTEMD_UNIT_NAME must not contain '/': ${unit_name}"
			;;
	esac

	ofgwrite_exec="$(resolve_executable "${OFGWRITE_BIN}" || true)"
	[ -n "${ofgwrite_exec}" ] || fail "cannot resolve ofgwrite executable: ${OFGWRITE_BIN}"

	unit_path="/run/systemd/system/${unit_name}"
	# This codepath is only reached when TARGET_IS_ACTIVE_SLOT=1 (see guard
	# above), so the transient unit must pass --allow-active-slot to
	# ofgwrite — the user already confirmed flashing the running slot.
	if [ "${ofgwrite_force}" = "1" ]; then
		exec_line="${ofgwrite_exec} -f --allow-active-slot -m ${slot} ${image_dir}"
	else
		exec_line="${ofgwrite_exec} --allow-active-slot -m ${slot} ${image_dir}"
	fi

	mkdir -p /run/systemd/system || fail "cannot create /run/systemd/system"
	rm -f "${unit_path}"
	cat >"${unit_path}" <<EOF
[Unit]
Description=Tuxbox active-slot flash via ofgwrite
After=local-fs.target

[Service]
Type=forking
GuessMainPID=no
RemainAfterExit=yes
KillMode=process
TimeoutStartSec=infinity
ExecStart=${exec_line}
StandardOutput=journal
StandardError=journal
EOF

	systemctl daemon-reload >/dev/null 2>&1 || fail "systemctl daemon-reload failed"
	systemctl reset-failed "${unit_name}" >/dev/null 2>&1 || true
	systemctl start "${unit_name}" >/dev/null 2>&1 || fail "unable to start ${unit_name}"
	trace "started active-slot flash via transient unit ${unit_name}: ${exec_line}"
	log "Started active-slot flash via ${unit_name}"
	return 0
}

run_active_slot_backup() {
	[ "${TARGET_IS_ACTIVE_SLOT}" = "1" ] || return 0
	if [ "${ACTIVE_SLOT_REQUIRE_BACKUP}" != "1" ]; then
		log "warning: active-slot backup disabled; proceeding without settings backup"
		return 0
	fi

	backup_cmd="$(resolve_executable "${BACKUP_BIN}" || true)"
	[ -n "${backup_cmd}" ] || fail "active-slot flash requires backup command but '${BACKUP_BIN}' is unavailable"
	mkdir -p "${ACTIVE_SLOT_BACKUP_DIR}" || fail "cannot create backup directory: ${ACTIVE_SLOT_BACKUP_DIR}"

	timestamp="$(date +%Y%m%d_%H%M%S)"
	backup_name="${ACTIVE_SLOT_BACKUP_NAME_PREFIX}${slot}-${timestamp}"
	backup_file="${ACTIVE_SLOT_BACKUP_DIR}/${backup_name}.tar.gz"
	log "creating settings backup for active slot ${slot}: ${backup_file}"
	"${backup_cmd}" "${ACTIVE_SLOT_BACKUP_DIR}" "${backup_name}" || fail "active-slot backup command failed"
	[ -s "${backup_file}" ] || fail "active-slot backup archive missing or empty: ${backup_file}"
}

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		fail "required command not found: $1"
	fi
}

get_config_string() {
	key="$1"
	default_value="$2"

	[ -f "${FLASH_VERSION_FILE}" ] || fail "config file not found: ${FLASH_VERSION_FILE}"

	value="$(awk -F= -v k="${key}" '$1 == k { sub("^[^=]*=", "", $0); print; exit }' "${FLASH_VERSION_FILE}")"
	if [ -z "${value}" ]; then
		value="${default_value}"
	fi

	printf '%s\n' "${value}"
}

maybe_get_machine_from_config() {
	if [ ! -f "${FLASH_VERSION_FILE}" ]; then
		printf '%s\n' ""
		return 0
	fi

	awk -F= '$1 == "machine" { sub("^[^=]*=", "", $0); print; exit }' "${FLASH_VERSION_FILE}"
}

has_kernel_file() {
	dir="$1"
	if [ -f "${dir}/kernel.bin" ] || [ -f "${dir}/uImage" ]; then
		return 0
	fi
	ls "${dir}"/*kernel*.bin >/dev/null 2>&1
}

has_rootfs_file() {
	dir="$1"
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

is_image_dir() {
	dir="$1"
	if [ ! -d "${dir}" ]; then
		return 1
	fi
	has_kernel_file "${dir}" && has_rootfs_file "${dir}"
}

resolve_image_dir() {
	base_dir="$1"
	machine_name="$2"

	if is_image_dir "${base_dir}"; then
		printf '%s\n' "${base_dir}"
		return 0
	fi

	if [ -n "${machine_name}" ] && is_image_dir "${base_dir}/${machine_name}"; then
		printf '%s\n' "${base_dir}/${machine_name}"
		return 0
	fi

	fail "no valid image directory found below: ${base_dir}"
}

detect_default_image_base() {
	if [ -n "${IMAGE_BASE_OVERRIDE}" ]; then
		printf '%s\n' "${IMAGE_BASE_OVERRIDE}"
		return 0
	fi

	work_dir="/tmp/.flash-backend-ofgwrite"
	mount_base="${work_dir}"
	mkdir -p "${work_dir}"

	for candidate in /media/usb /media/USB /media/hdd /media/Generic-; do
		if grep -q " ${candidate} " /proc/mounts 2>/dev/null; then
			mount_base="${candidate}"
			break
		fi
	done

	printf '%s\n' "${mount_base}/service/image"
}

load_flash_metadata() {
	IMAGE_UPDATE_URL="$(get_config_string "image_update_url" "file:///media/sda1/service/images")"
	INFO_FILE_NAME="$(get_config_string "image_update_info_file" "imageversion")"
	IMAGE_NAME="$(get_config_string "imagename" "neutrino-image")"
	MACHINE="$(get_config_string "machine" "")"
	[ -n "${MACHINE}" ] || fail "missing 'machine' in ${FLASH_VERSION_FILE}"
	IMAGE_FILE_NAME="$(get_config_string "image_file_name" "${IMAGE_NAME}_${MACHINE}_ofgwrite.zip")"
	IMAGE_SOURCE="${IMAGE_UPDATE_URL}/${IMAGE_FILE_NAME}"
	IMAGE_VERSION_ONLINE="${IMAGE_UPDATE_URL}/${INFO_FILE_NAME}"
}

slot="${1:-}"
source_mode="${2:-}"
force_arg="${3:-}"

if [ -z "${slot}" ] || [ "${slot}" = "-h" ] || [ "${slot}" = "--help" ]; then
	print_usage
	exit 0
fi

if [ "$#" -gt 3 ]; then
	fail "too many arguments"
fi

case "${slot}" in
	*[!0-9]*|'')
		fail "slot must be a positive integer"
		;;
esac

if [ "${slot}" -lt 1 ]; then
	fail "slot must be >= 1"
fi

validate_bool "FLASH_ALLOW_ACTIVE_SLOT" "${ALLOW_ACTIVE_SLOT}"
validate_bool "FLASH_ACTIVE_SLOT_REQUIRE_BACKUP" "${ACTIVE_SLOT_REQUIRE_BACKUP}"
validate_bool "FLASH_BACKEND_TRACE_ENABLE" "${TRACE_ENABLE}"
case "${ACTIVE_SLOT_BACKUP_DIR}" in
	/*)
		;;
	*)
		fail "FLASH_ACTIVE_SLOT_BACKUP_DIR must be absolute: ${ACTIVE_SLOT_BACKUP_DIR}"
		;;
esac
trace_init
trace "invocation: slot=${slot} source_mode='${source_mode}' force_arg='${force_arg}'"
trace "config: allow_active=${ALLOW_ACTIVE_SLOT} require_backup=${ACTIVE_SLOT_REQUIRE_BACKUP} stop_neutrino=${STOP_NEUTRINO_BEFORE_FLASH}"
trace_runtime_snapshot
ensure_not_active_slot "${slot}"
cleanup_stale_ofgwrite_runtime
verify_active_slot_runtime_prereqs

ofgwrite_force="0"
if [ -n "${force_arg}" ]; then
	if [ "${force_arg}" = "force" ]; then
		ofgwrite_force="1"
	else
		fail "unsupported third argument '${force_arg}' (allowed: force)"
	fi
fi

mode="download-check"
image_base=""
case "${source_mode}" in
	"")
		mode="download-check"
		;;
	force)
		mode="download-force"
		;;
	restore)
		mode="restore"
		;;
	/*)
		mode="local-path"
		image_base="${source_mode}"
		;;
	*)
		fail "invalid second argument '${source_mode}' (expected: /abs/path, restore or force)"
		;;
esac

machine_from_file="$(maybe_get_machine_from_config)"
trace "machine from image-version='${machine_from_file}'"

if [ "${mode}" = "local-path" ]; then
	image_dir="$(resolve_image_dir "${image_base}" "${machine_from_file}")"
else
	load_flash_metadata
	default_base="$(detect_default_image_base)"
	image_base="${default_base}"
	if [ "${mode}" = "restore" ]; then
		image_base="${default_base}/backup/partition_${slot}"
		image_dir="$(resolve_image_dir "${image_base}" "${MACHINE}")"
	else
		require_command "${CURL_BIN}"
		require_command "${UNZIP_BIN}"
		mkdir -p "${image_base}"

		image_file="${image_base}/${IMAGE_FILE_NAME}"
		image_version_local="${image_base}/imageversion_partition_${slot}"
		online_version_tmp="${image_base}/.imageversion_partition_${slot}.online"

		if [ "${mode}" = "download-check" ]; then
			"${CURL_BIN}" -fsSL "${IMAGE_VERSION_ONLINE}" -o "${online_version_tmp}" || fail "unable to fetch online imageversion: ${IMAGE_VERSION_ONLINE}"
			[ -f "${image_version_local}" ] || : > "${image_version_local}"

			md5_online="$(md5sum "${online_version_tmp}" | awk '{print $1}')"
			md5_local="$(md5sum "${image_version_local}" | awk '{print $1}')"
			if [ "${md5_online}" = "${md5_local}" ]; then
				rm -f "${online_version_tmp}"
				log "No update available"
				exit 0
			fi
		fi

		log "Downloading ${IMAGE_SOURCE}"
		"${CURL_BIN}" -fL "${IMAGE_SOURCE}" -o "${image_file}" || fail "download failed: ${IMAGE_SOURCE}"
		"${UNZIP_BIN}" -o "${image_file}" -d "${image_base}" || fail "unpack failed: ${image_file}"
		rm -f "${image_file}"

		if [ -f "${online_version_tmp}" ]; then
			mv -f "${online_version_tmp}" "${image_version_local}"
		else
			"${CURL_BIN}" -fsSL "${IMAGE_VERSION_ONLINE}" -o "${image_version_local}" || true
		fi

		image_dir="$(resolve_image_dir "${image_base}" "${MACHINE}")"
	fi
fi

[ -x "${BACKEND_PREFLIGHT_BIN}" ] || fail "preflight command not executable: ${BACKEND_PREFLIGHT_BIN}"
trace "resolved mode=${mode} image_base='${image_base}' image_dir='${image_dir}'"
trace_image_payload "${image_dir}"
trace "running preflight: ${BACKEND_PREFLIGHT_BIN} --backend ofgwrite --ofgwrite-bin ${OFGWRITE_BIN} --image-dir ${image_dir}"

"${BACKEND_PREFLIGHT_BIN}" --backend ofgwrite --ofgwrite-bin "${OFGWRITE_BIN}" --image-dir "${image_dir}"
stop_frontend_runtime
run_active_slot_backup

if start_active_slot_systemd_flash; then
	exit 0
fi

extra_args=""
if [ -n "${FLASH_OFGWRITE_EXTRA_ARGS:-}" ]; then
	extra_args="${FLASH_OFGWRITE_EXTRA_ARGS}"
fi

if [ "${ofgwrite_force}" = "1" ]; then
	trace "exec: ${OFGWRITE_BIN} ${extra_args} -f -m ${slot} ${image_dir}"
	# shellcheck disable=SC2086
	exec "${OFGWRITE_BIN}" ${extra_args} -f -m "${slot}" "${image_dir}"
fi

trace "exec: ${OFGWRITE_BIN} ${extra_args} -m ${slot} ${image_dir}"
# shellcheck disable=SC2086
exec "${OFGWRITE_BIN}" ${extra_args} -m "${slot}" "${image_dir}"
