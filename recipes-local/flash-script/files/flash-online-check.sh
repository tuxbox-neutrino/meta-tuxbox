#!/bin/sh
# flash-online-check: compare local build against remote feed manifest.
# MVP: latest-check only. Auto-detects portal-wrapper response
# ({"ok":true,"item":{...}}) vs a direct manifest.json. Busybox-safe
# (POSIX shell + awk; no jq dependency).

LOG_TAG="flash-online-check"
VERSION_FILE="${FLASH_VERSION_FILE_PATH:-/etc/image-version}"
CURL_BIN="${FLASH_CURL_BIN:-curl}"

JSON_MODE=0
URL_OVERRIDE=""
KEY_CLI=""

err() { printf '%s: %s\n' "${LOG_TAG}" "$*" >&2; }

usage() {
	cat >&2 <<'EOF'
Usage: flash-online-check [--json] [--key <value>] [--url <url>]

Check whether a newer image is available for this box.

Options:
  --json        Emit machine-readable JSON result.
  --key <val>   Service key (alt: TUXBOX_SERVICE_KEY env).
  --url <val>   Full manifest or API URL override.
  -h, --help    Show this help.

Exit codes:
  0 success (check ran; update may or may not be available)
  1 generic failure
  2 invalid input / no valid image source
  3 preflight failure (HTTP 401/403, DNS, timeout)
  5 manifest integrity / validation failure
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		--json) JSON_MODE=1; shift ;;
		--key)  KEY_CLI="${2-}"; shift 2 ;;
		--url)  URL_OVERRIDE="${2-}"; shift 2 ;;
		-h|--help) usage; exit 0 ;;
		*) err "unknown argument: $1"; usage; exit 2 ;;
	esac
done

SERVICE_KEY="${KEY_CLI:-${TUXBOX_SERVICE_KEY:-}}"

# /etc/image-version key reader, strips optional surrounding quotes.
image_kv_get() {
	_k="$1"; _fb="${2-}"
	_v=$(sed -n "s/^${_k}=\\(.*\\)\$/\\1/p" "${VERSION_FILE}" 2>/dev/null \
		| head -n1)
	_v="${_v%\"}"; _v="${_v#\"}"
	if [ -z "${_v}" ]; then printf '%s' "${_fb}"; else printf '%s' "${_v}"; fi
}

LOCAL_BUILD_DATE=""
LOCAL_IMAGE_VERSION=""
IMAGE_UPDATE_URL=""
IMAGE_DISCOVERY_API_URL=""
IMAGE_MANIFEST_FILE="manifest.json"
CHANNEL=""
IMAGEDIR=""

if [ -r "${VERSION_FILE}" ]; then
	LOCAL_BUILD_DATE=$(image_kv_get build_date)
	LOCAL_IMAGE_VERSION=$(image_kv_get image_version)
	IMAGE_UPDATE_URL=$(image_kv_get image_update_url)
	IMAGE_DISCOVERY_API_URL=$(image_kv_get image_discovery_api_url)
	IMAGE_MANIFEST_FILE=$(image_kv_get image_manifest_file manifest.json)
	CHANNEL=$(image_kv_get channel)
	IMAGEDIR=$(image_kv_get imagedir)
fi

# Discovery priority: --url > image_discovery_api_url > image_update_url.
if [ -n "${URL_OVERRIDE}" ]; then
	TARGET_URL="${URL_OVERRIDE}"
elif [ -n "${IMAGE_DISCOVERY_API_URL}" ]; then
	if [ -z "${CHANNEL}" ] || [ -z "${IMAGEDIR}" ]; then
		err "channel or imagedir missing from ${VERSION_FILE}"
		exit 2
	fi
	_api="${IMAGE_DISCOVERY_API_URL%/}"
	TARGET_URL="${_api}/latest.php?channel=${CHANNEL}&imagedir=${IMAGEDIR}"
elif [ -n "${IMAGE_UPDATE_URL}" ]; then
	TARGET_URL="${IMAGE_UPDATE_URL%/}/${IMAGE_MANIFEST_FILE}"
else
	err "no image source (image_update_url and image_discovery_api_url empty)"
	exit 2
fi

BODY_FILE=$(mktemp /tmp/flash-online-check.XXXXXX) || {
	err "mktemp failed"
	exit 1
}
trap 'rm -f "${BODY_FILE}"' EXIT INT TERM

# Fetch without --fail so any HTTP status reaches us via -w.
CURL_RC=0
if [ -n "${SERVICE_KEY}" ]; then
	HTTP_STATUS=$("${CURL_BIN}" -sS --max-time 15 -o "${BODY_FILE}" \
		-w '%{http_code}' \
		-H "X-Tuxbox-Service-Key: ${SERVICE_KEY}" \
		"${TARGET_URL}" 2>/dev/null) || CURL_RC=$?
else
	HTTP_STATUS=$("${CURL_BIN}" -sS --max-time 15 -o "${BODY_FILE}" \
		-w '%{http_code}' \
		"${TARGET_URL}" 2>/dev/null) || CURL_RC=$?
fi

if [ "${CURL_RC}" -ne 0 ] || [ -z "${HTTP_STATUS}" ]; then
	err "transport error fetching ${TARGET_URL} (curl rc=${CURL_RC})"
	exit 3
fi

case "${HTTP_STATUS}" in
	2??) : ;;
	401|403)
		err "HTTP ${HTTP_STATUS} from ${TARGET_URL} (check service key)"
		exit 3
		;;
	404)
		err "HTTP 404 from ${TARGET_URL}"
		exit 2
		;;
	*)
		err "unexpected HTTP ${HTTP_STATUS} from ${TARGET_URL}"
		exit 1
		;;
esac

# Extract first occurrence of a flat scalar field from the body.
# Body is read as one record (RS=\0) so line layout does not matter.
# The fields we need (schema_version, build_date, image_version,
# image_name) are unique within both portal-wrapper and direct-manifest
# shapes, so first-match is safe.
json_get() {
	awk -v k="$1" '
		BEGIN { RS = "\0" }
		{
			pat = "\"" k "\"[[:space:]]*:[[:space:]]*\"?([^\",}[:space:]]+)"
			if (match($0, pat)) {
				s = substr($0, RSTART, RLENGTH)
				sub(".*:[[:space:]]*\"?", "", s)
				print s
				exit
			}
		}
	' "${BODY_FILE}"
}

SCHEMA=$(json_get schema_version)
REMOTE_BUILD_DATE=$(json_get build_date)
REMOTE_IMAGE_VERSION=$(json_get image_version)
REMOTE_IMAGE_NAME=$(json_get image_name)

if [ "${SCHEMA}" != "1" ]; then
	err "unsupported or missing schema_version '${SCHEMA}' in response"
	exit 5
fi
if [ -z "${REMOTE_BUILD_DATE}" ] \
	|| [ -z "${REMOTE_IMAGE_VERSION}" ] \
	|| [ -z "${REMOTE_IMAGE_NAME}" ]; then
	err "required field missing in response" \
		"(build_date/image_version/image_name)"
	exit 5
fi

UPDATE_AVAILABLE=0
if [ -n "${LOCAL_BUILD_DATE}" ] \
	&& [ "${REMOTE_BUILD_DATE}" \> "${LOCAL_BUILD_DATE}" ]; then
	UPDATE_AVAILABLE=1
fi

if [ "${JSON_MODE}" -eq 1 ]; then
	if [ "${UPDATE_AVAILABLE}" -eq 1 ]; then
		_ua=true
	else
		_ua=false
	fi
	cat <<EOF
{
  "schema_version": 1,
  "source": "${TARGET_URL}",
  "current": {
    "build_date": "${LOCAL_BUILD_DATE}",
    "image_version": "${LOCAL_IMAGE_VERSION}"
  },
  "latest": {
    "build_date": "${REMOTE_BUILD_DATE}",
    "image_version": "${REMOTE_IMAGE_VERSION}",
    "image_name": "${REMOTE_IMAGE_NAME}"
  },
  "update_available": ${_ua}
}
EOF
else
	printf 'Current: %s (build %s)\n' \
		"${LOCAL_IMAGE_VERSION}" "${LOCAL_BUILD_DATE}"
	printf 'Latest:  %s (build %s)\n' \
		"${REMOTE_IMAGE_VERSION}" "${REMOTE_BUILD_DATE}"
	if [ "${UPDATE_AVAILABLE}" -eq 1 ]; then
		printf 'Update available.\n'
	else
		printf 'No update available.\n'
	fi
fi

exit 0
