#!/bin/sh
set -eu

BACKEND_CONF="/etc/tuxbox/flash-backend.conf"

backend_override=""
image_dir=""
ofgwrite_bin="${OFGWRITE_BIN:-ofgwrite}"
quiet=0

print_usage() {
	cat <<'EOF'
Usage: flash-backend-preflight [options]

Options:
  --backend <script|ofgwrite>  Override backend (default: value from /etc/tuxbox/flash-backend.conf)
  --image-dir <dir>            Image directory for ofgwrite no-write test
  --ofgwrite-bin <path>        Override ofgwrite executable (default: OFGWRITE_BIN or "ofgwrite")
  --quiet                      Suppress informational output
  -h, --help                   Show this help
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
		if ! command -v "${ofgwrite_bin}" >/dev/null 2>&1; then
			fail "backend=ofgwrite but executable not found: ${ofgwrite_bin}"
		fi

		if [ -z "${image_dir}" ]; then
			if "${ofgwrite_bin}" --help >/dev/null 2>&1; then
				log "flash preflight ok: backend=ofgwrite binary is callable"
				log "hint: pass --image-dir <dir> to run no-write preflight"
				exit 0
			fi
			fail "backend=ofgwrite but '${ofgwrite_bin} --help' failed"
		fi

		[ -d "${image_dir}" ] || fail "image directory does not exist: ${image_dir}"
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
