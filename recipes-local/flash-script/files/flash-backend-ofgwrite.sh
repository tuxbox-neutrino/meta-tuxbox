#!/bin/sh
set -eu

BACKEND_PREFLIGHT_BIN="${FLASH_BACKEND_PREFLIGHT_BIN:-/usr/bin/flash-backend-preflight}"
OFGWRITE_BIN="${FLASH_BACKEND_OFGWRITE_BIN:-ofgwrite}"
FLASH_VERSION_FILE="${FLASH_VERSION_FILE_PATH:-/etc/image-version}"
CURL_BIN="${FLASH_CURL_BIN:-curl}"
UNZIP_BIN="${FLASH_UNZIP_BIN:-unzip}"
IMAGE_BASE_OVERRIDE="${FLASH_IMAGE_BASE_OVERRIDE:-}"

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

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
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

"${BACKEND_PREFLIGHT_BIN}" --backend ofgwrite --ofgwrite-bin "${OFGWRITE_BIN}" --image-dir "${image_dir}"

if [ "${ofgwrite_force}" = "1" ]; then
	exec "${OFGWRITE_BIN}" -f -m "${slot}" "${image_dir}"
fi

exec "${OFGWRITE_BIN}" -m "${slot}" "${image_dir}"
