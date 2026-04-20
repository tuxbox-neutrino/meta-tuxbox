#!/bin/sh
# Tuxbox flash-restore: first-boot helper that restores a settings
# archive staged by ofgwrite --inject-backup / --inject-marker. The
# paired systemd unit only invokes this script while the marker file
# exists, so the service is idempotent across reboots.

set -u

MARKER="${FLASH_RESTORE_MARKER:-/etc/neutrino/flash-restore-pending.conf}"
LOG_TAG="tuxbox-flash-restore"

log() {
	logger -t "${LOG_TAG}" -- "$*" 2>/dev/null || true
	printf '%s: %s\n' "${LOG_TAG}" "$*"
}

if [ ! -r "${MARKER}" ]; then
	log "no marker at ${MARKER}, nothing to do"
	exit 0
fi

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
	log "restore succeeded, removing marker"
	rm -f "${MARKER}"
	exit 0
fi

log "restore failed, leaving marker in place for retry"
exit 1
