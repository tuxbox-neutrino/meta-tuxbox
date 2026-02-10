#!/bin/sh
set -eu

BACKEND_PREFLIGHT_BIN="${FLASH_BACKEND_PREFLIGHT_BIN:-/usr/bin/flash-backend-preflight}"
OFGWRITE_BIN="${FLASH_BACKEND_OFGWRITE_BIN:-ofgwrite}"

print_usage() {
	cat <<'EOF'
Usage: flash <slot> <image-dir> [force]

ofgwrite backend mode:
  slot      positive integer multiboot slot number
  image-dir absolute path to unpacked image directory
  force     optional, forwards -f to ofgwrite

Examples:
  flash 2 /media/usb/images/zgemmah7
  flash 3 /media/hdd/images/hd51 force
EOF
}

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

slot="${1:-}"
image_dir="${2:-}"
force_arg="${3:-}"

if [ -z "${slot}" ] || [ "${slot}" = "-h" ] || [ "${slot}" = "--help" ]; then
	print_usage
	exit 0
fi

case "${slot}" in
	*[!0-9]*|'')
		fail "slot must be a positive integer"
		;;
esac

if [ "${slot}" -lt 1 ]; then
	fail "slot must be >= 1"
fi

if [ -z "${image_dir}" ]; then
	fail "missing image-dir argument"
fi

case "${image_dir}" in
	/*)
		;;
	force|restore)
		fail "mode '${image_dir}' is not supported by ofgwrite backend"
		;;
	*)
		fail "image-dir must be an absolute path"
		;;
esac

ofgwrite_force=""
if [ -n "${force_arg}" ]; then
	if [ "${force_arg}" = "force" ]; then
		ofgwrite_force="-f"
	else
		fail "unsupported third argument '${force_arg}' (allowed: force)"
	fi
fi

if [ ! -x "${BACKEND_PREFLIGHT_BIN}" ]; then
	fail "preflight command not executable: ${BACKEND_PREFLIGHT_BIN}"
fi

"${BACKEND_PREFLIGHT_BIN}" --backend ofgwrite --ofgwrite-bin "${OFGWRITE_BIN}" --image-dir "${image_dir}"

if [ -n "${ofgwrite_force}" ]; then
	exec "${OFGWRITE_BIN}" -f -m "${slot}" "${image_dir}"
fi

exec "${OFGWRITE_BIN}" -m "${slot}" "${image_dir}"
