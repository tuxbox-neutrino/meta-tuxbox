#!/bin/sh
set -eu

LEGACY_FLASH_BIN="${FLASH_LEGACY_BIN:-/usr/bin/flash-legacy}"

if [ ! -x "${LEGACY_FLASH_BIN}" ]; then
	printf 'ERROR: legacy flash script not executable: %s\n' "${LEGACY_FLASH_BIN}" >&2
	exit 1
fi

exec "${LEGACY_FLASH_BIN}" "$@"
