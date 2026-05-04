#!/bin/sh
# Tuxbox flash-restore: first-boot helper that restores a settings
# archive staged by ofgwrite --inject-backup / --inject-marker. The
# script also checks the backup directory for a fallback marker, so the
# service remains idempotent even if the primary marker is lost.

set -u

PRIMARY_MARKER="${FLASH_RESTORE_MARKER:-/etc/neutrino/flash-restore-pending.conf}"
FALLBACK_DIR="${FLASH_RESTORE_FALLBACK_DIR:-/var/lib/neutrino-backups}"
MARKER="${PRIMARY_MARKER}"
LOG_TAG="tuxbox-flash-restore"

log() {
	logger -t "${LOG_TAG}" -- "$*" 2>/dev/null || true
	printf '%s: %s\n' "${LOG_TAG}" "$*"
}

find_marker() {
	if [ -r "${PRIMARY_MARKER}" ]; then
		MARKER="${PRIMARY_MARKER}"
		return 0
	fi

	set -- "${FALLBACK_DIR}"/*.flash-restore-pending.json
	if [ -r "$1" ]; then
		MARKER="$1"
		log "primary marker missing, using fallback marker ${MARKER}"
		return 0
	fi

	log "no marker at ${PRIMARY_MARKER} or ${FALLBACK_DIR}, nothing to do"
	exit 0
}

find_marker

# Minimal JSON field extractor for the flat, one-field-per-line marker
# written by flash-backend-ofgwrite.sh. Handles quoted strings and bare
# numeric values.
json_get() {
	awk -v k="$1" '
		{
			pat = "\"" k "\"[[:space:]]*:[[:space:]]*\"?([^\",}[:space:]]+)"
			if (match($0, pat)) {
				s = substr($0, RSTART, RLENGTH)
				sub(".*:[[:space:]]*\"?", "", s)
				print s
				exit
			}
		}
	' "${MARKER}"
}

schema="$(json_get schema_version)"
backup_path="$(json_get backup_relpath)"
backup_name="$(json_get backup_file)"

if [ "${schema}" != "1" ]; then
	log "unsupported schema_version='${schema}' in ${MARKER}"
	exit 1
fi
if [ -z "${backup_path}" ]; then
	log "marker missing backup_relpath"
	exit 1
fi
if [ ! -f "${backup_path}" ]; then
	log "backup archive not found: ${backup_path}"
	exit 1
fi

log "restoring settings from ${backup_path} (${backup_name:-?})"
if tar -xzpf "${backup_path}" -C /; then
	fallback_marker=""
	if [ -n "${backup_name}" ]; then
		fallback_marker="${FALLBACK_DIR}/${backup_name%.tar.gz}.flash-restore-pending.json"
	fi
	log "restore succeeded, removing marker"
	rm -f "${PRIMARY_MARKER}" "${MARKER}" ${fallback_marker:+"${fallback_marker}"}
	exit 0
fi

log "restore failed, leaving marker in place for retry"
exit 1
