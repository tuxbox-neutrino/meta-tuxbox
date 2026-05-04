#!/bin/sh
set -eu

BACKEND_CONF="${FLASH_BACKEND_CONF_PATH:-/etc/tuxbox/flash-backend.conf}"
PROFILE_CONF="${FLASH_MACHINE_PROFILE_PATH:-/etc/tuxbox/flash-machine-profile.conf}"

backend_override=""
image_dir=""
ofgwrite_bin="${OFGWRITE_BIN:-ofgwrite}"
quiet=0
run_nowrite_probe="${FLASH_PREFLIGHT_RUN_OFGWRITE_NOWRITE:-0}"

print_usage() {
	cat <<'EOF'
Usage: flash-backend-preflight [options]

Options:
  --backend <script|ofgwrite>  Override backend (default: value from /etc/tuxbox/flash-backend.conf)
  --image-dir <dir>            Image directory for ofgwrite no-write test
  --ofgwrite-bin <path>        Override ofgwrite executable (default: OFGWRITE_BIN or "ofgwrite")
  --quiet                      Suppress informational output
  -h, --help                   Show this help

Environment overrides:
  FLASH_BACKEND_CONF_PATH      Backend config file (default: /etc/tuxbox/flash-backend.conf)
  FLASH_MACHINE_PROFILE_PATH   Machine profile file (default: /etc/tuxbox/flash-machine-profile.conf)
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
