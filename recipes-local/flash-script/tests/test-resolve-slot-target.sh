#!/bin/sh
# Resolution tests for flash-backend-script.sh.
#
# Runs the backend in FLASH_RESOLVE_ONLY mode against synthetic boot
# directories, partlabel directories and machine profiles, so no box and no
# root privileges are needed. Not shipped: this file is not in the recipe
# SRC_URI.
#
# Usage: tests/test-resolve-slot-target.sh [path-to-flash-backend-script.sh]

set -eu

BACKEND="${1:-$(dirname "$0")/../files/flash-backend-script.sh}"
[ -r "${BACKEND}" ] || { printf 'ERROR: backend not found: %s\n' "${BACKEND}" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT INT TERM

passed=0
failed=0

# --- fixtures ---------------------------------------------------------------

# startup <case> <slot> <root-device> <rootsubdir> [kernel-device]
startup() {
	mkdir -p "${WORK}/$1/boot"
	printf "boot emmcflash0.linuxkernel%s 'root=%s rootsubdir=%s kernel=%s rw rootwait'\n" \
		"$2" "$3" "$4" "${5:-/dev/mmcblk0p6}" > "${WORK}/$1/boot/STARTUP_LINUX_$2"
}

# partlabel <case> <label> <device>
partlabel() {
	mkdir -p "${WORK}/$1/partlabel" "${WORK}/$1/dev"
	: > "${WORK}/$1/dev/$3"
	ln -sf "${WORK}/$1/dev/$3" "${WORK}/$1/partlabel/$2"
}

# device <case> <device>
device() {
	mkdir -p "${WORK}/$1/dev"
	: > "${WORK}/$1/dev/$2"
}

# profile <case> <mtd-rootfs>
profile() {
	mkdir -p "${WORK}/$1"
	cat > "${WORK}/$1/profile.conf" <<EOF
FLASH_MTD_ROOTFS="$2"
FLASH_MTD_KERNEL="mmcblk0p2"
FLASH_ROOTFS_SUBDIR_PREFIX="linuxrootfs"
FLASH_SLOT_ROOTFS_SHARED_LABEL="userdata"
FLASH_SCRIPT_MODE="legacy"
EOF
}

# cmdline <case> <active-rootsubdir>
cmdline() {
	mkdir -p "${WORK}/$1"
	printf 'root=/dev/mmcblk0p7 rootsubdir=%s rw\n' "$2" > "${WORK}/$1/cmdline"
}

resolve() {
	case_name="$1"
	slot="$2"
	FLASH_RESOLVE_ONLY=1 \
	FLASH_LEGACY_BIN=/bin/true \
	FLASH_MACHINE_PROFILE_PATH="${WORK}/${case_name}/profile.conf" \
	FLASH_BOOT_DIR_PATH="${WORK}/${case_name}/boot" \
	FLASH_PARTLABEL_DIR_PATH="${WORK}/${case_name}/partlabel" \
	FLASH_DEV_DIR="${WORK}/${case_name}/dev" \
	FLASH_PROC_CMDLINE_FILE="${WORK}/${case_name}/cmdline" \
	FLASH_TARGET_MOUNT_DIR="${WORK}/${case_name}/mnt" \
		sh "${BACKEND}" "${slot}" 2>&1
}

# --- assertions -------------------------------------------------------------

expect_device() {
	name="$1"; case_name="$2"; slot="$3"; want="$4"
	if ! out="$(resolve "${case_name}" "${slot}")"; then
		printf 'FAIL %s: resolution failed unexpectedly\n     %s\n' "${name}" "${out}"
		failed=$((failed + 1))
		return 0
	fi
	got="$(printf '%s\n' "${out}" | sed -n 's/.*device=\([^ ]*\).*/\1/p')"
	if [ "${got}" = "${want}" ]; then
		printf 'PASS %s (%s)\n' "${name}" "${got}"
		passed=$((passed + 1))
	else
		printf 'FAIL %s: expected %s, got "%s"\n     %s\n' "${name}" "${want}" "${got}" "${out}"
		failed=$((failed + 1))
	fi
}

expect_refusal() {
	name="$1"; case_name="$2"; slot="$3"; needle="$4"
	if out="$(resolve "${case_name}" "${slot}")"; then
		printf 'FAIL %s: expected a refusal, but it resolved\n     %s\n' "${name}" "${out}"
		failed=$((failed + 1))
		return 0
	fi
	case "${out}" in
		*"${needle}"*)
			printf 'PASS %s (refused)\n' "${name}"
			passed=$((passed + 1))
			;;
		*)
			printf 'FAIL %s: refused, but message lacks "%s"\n     %s\n' "${name}" "${needle}" "${out}"
			failed=$((failed + 1))
			;;
	esac
}

# --- cases ------------------------------------------------------------------

# 1+2: hd51 split layout — slot 1 on p3, shared slots on p7. This is the
#      regression guard for the incident: slot 4 must never resolve to p3.
for c in hd51_from_slot3 hd51_from_slot1; do
	profile "${c}" "mmcblk0p3"
	partlabel "${c}" userdata mmcblk0p7
	device "${c}" mmcblk0p3
	startup "${c}" 4 /dev/mmcblk0p7 linuxrootfs4
	startup "${c}" 1 /dev/mmcblk0p3 linuxrootfs1
done
cmdline hd51_from_slot3 linuxrootfs3
cmdline hd51_from_slot1 linuxrootfs1

expect_device "hd51 slot 4 from a test slot resolves to the shared partition" \
	hd51_from_slot3 4 /dev/mmcblk0p7
expect_device "hd51 slot 4 from the production slot resolves to the shared partition" \
	hd51_from_slot1 4 /dev/mmcblk0p7

# 3: same layout, but STARTUP entries are missing -> partlabel takes over.
profile hd51_no_startup "mmcblk0p3"
partlabel hd51_no_startup userdata mmcblk0p7
device hd51_no_startup mmcblk0p3
mkdir -p "${WORK}/hd51_no_startup/boot"
cmdline hd51_no_startup linuxrootfs3
expect_device "hd51 without STARTUP entries falls back to the userdata partlabel" \
	hd51_no_startup 4 /dev/mmcblk0p7

# 4: neither STARTUP nor a usable partlabel, but the profile rootfs is known to
#    be a slot-1-only partition -> must refuse instead of writing there.
#    (partlabel dir exists but is empty, as after a failed coldplug)
profile hd51_blind "mmcblk0p3"
mkdir -p "${WORK}/hd51_blind/boot" "${WORK}/hd51_blind/partlabel"
device hd51_blind mmcblk0p3
cmdline hd51_blind linuxrootfs3
expect_device "blind layout keeps the previous behaviour (no shared partition known)" \
	hd51_blind 4 /dev/mmcblk0p3

# 5: hd60 pattern — no STARTUP mechanism, no shared partlabel. Must keep
#    working exactly as before.
profile hd60 "mmcblk0p23"
mkdir -p "${WORK}/hd60/boot" "${WORK}/hd60/partlabel"
device hd60 mmcblk0p23
cmdline hd60 linuxrootfs1
expect_device "hd60 pattern without STARTUP keeps using the profile rootfs" \
	hd60 2 /dev/mmcblk0p23

# 6: h7 pattern — profile rootfs p3, but STARTUP puts the slots on p8.
profile h7 "mmcblk0p3"
partlabel h7 userdata mmcblk0p8
device h7 mmcblk0p3
startup h7 2 /dev/mmcblk0p8 linuxrootfs2
cmdline h7 linuxrootfs1
expect_device "h7 pattern follows STARTUP to the slot partition, not the profile rootfs" \
	h7 2 /dev/mmcblk0p8

# 7: STARTUP entry for the slot names a foreign rootsubdir -> refuse.
profile mismatch "mmcblk0p3"
partlabel mismatch userdata mmcblk0p7
device mismatch mmcblk0p3
startup mismatch 4 /dev/mmcblk0p7 linuxrootfs2
cmdline mismatch linuxrootfs3
expect_refusal "mismatched rootsubdir is refused" \
	mismatch 4 "expected 'linuxrootfs4'"

# 8: slot 1 still resolves to its own partition.
expect_device "slot 1 resolves to the slot-1 partition" \
	hd51_from_slot3 1 /dev/mmcblk0p3

# 9: STARTUP points at a device that is neither profile rootfs nor shared.
profile foreign "mmcblk0p3"
partlabel foreign userdata mmcblk0p7
device foreign mmcblk0p3
startup foreign 4 /dev/sda1 linuxrootfs4
cmdline foreign linuxrootfs3
expect_refusal "a rootfs device outside the profile contract is refused" \
	foreign 4 "refusing to flash an incompatible layout"

# 10: an explicit caller override wins over any resolution.
FLASH_DESTINATION_BASE=/mnt/somewhere \
	out="$(FLASH_DESTINATION_BASE=/mnt/somewhere resolve hd51_from_slot3 4)"
case "${out}" in
	*"caller-provided destination base /mnt/somewhere"*)
		printf 'PASS explicit FLASH_DESTINATION_BASE is honoured\n'
		passed=$((passed + 1))
		;;
	*)
		printf 'FAIL explicit FLASH_DESTINATION_BASE ignored\n     %s\n' "${out}"
		failed=$((failed + 1))
		;;
esac

# --- summary ----------------------------------------------------------------

printf '\n%s passed, %s failed\n' "${passed}" "${failed}"
[ "${failed}" -eq 0 ]
