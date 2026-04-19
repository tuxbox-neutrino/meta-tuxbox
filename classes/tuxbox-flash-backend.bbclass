# Tuxbox flash backend capability model
#
# Supported backends:
# - script   : shell-based flash workflow (default)
# - ofgwrite : ofgwrite-based flash workflow

TUXBOX_FLASH_BACKEND_VALID ?= "script ofgwrite"
TUXBOX_FLASH_BACKEND ?= "script"
TUXBOX_FLASH_MACHINE_CAP_OFGWRITE_VALID ?= "0 1"
TUXBOX_FLASH_MACHINE_CAP_OFGWRITE ?= "${@'0' if (d.getVar('MACHINE') or '').startswith('qemu') else '1'}"
TUXBOX_FLASH_SCRIPT_MODE_VALID ?= "legacy"
TUXBOX_FLASH_SCRIPT_MODE ?= "legacy"
TUXBOX_FLASH_SCRIPT_GIT_BRANCH ?= "master"
TUXBOX_FLASH_OFGWRITE_ALLOW_ACTIVE_SLOT_VALID ?= "0 1"
TUXBOX_FLASH_OFGWRITE_ALLOW_ACTIVE_SLOT ?= "0"
TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_REQUIRE_BACKUP_VALID ?= "0 1"
TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_REQUIRE_BACKUP ?= "1"
TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_BACKUP_DIR ?= "/var/volatile/flash-backup"

TUXBOX_FLASH_USES_OFGWRITE = "${@'1' if (d.getVar('TUXBOX_FLASH_BACKEND') or '').strip() == 'ofgwrite' else '0'}"

python __anonymous() {
    backend = (d.getVar("TUXBOX_FLASH_BACKEND") or "").strip()
    valid = (d.getVar("TUXBOX_FLASH_BACKEND_VALID") or "").split()
    cap_ofgwrite = (d.getVar("TUXBOX_FLASH_MACHINE_CAP_OFGWRITE") or "").strip()
    cap_valid = (d.getVar("TUXBOX_FLASH_MACHINE_CAP_OFGWRITE_VALID") or "").split()
    script_mode = (d.getVar("TUXBOX_FLASH_SCRIPT_MODE") or "").strip()
    script_mode_valid = (d.getVar("TUXBOX_FLASH_SCRIPT_MODE_VALID") or "").split()
    script_branch = (d.getVar("TUXBOX_FLASH_SCRIPT_GIT_BRANCH") or "").strip()
    allow_active_slot = (d.getVar("TUXBOX_FLASH_OFGWRITE_ALLOW_ACTIVE_SLOT") or "").strip()
    allow_active_slot_valid = (
        d.getVar("TUXBOX_FLASH_OFGWRITE_ALLOW_ACTIVE_SLOT_VALID") or ""
    ).split()
    active_slot_require_backup = (
        d.getVar("TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_REQUIRE_BACKUP") or ""
    ).strip()
    active_slot_require_backup_valid = (
        d.getVar("TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_REQUIRE_BACKUP_VALID") or ""
    ).split()
    active_slot_backup_dir = (
        d.getVar("TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_BACKUP_DIR") or ""
    ).strip()

    if not backend:
        bb.fatal("TUXBOX_FLASH_BACKEND is empty")
    if backend not in valid:
        bb.fatal(
            "Invalid TUXBOX_FLASH_BACKEND '%s' (valid: %s)"
            % (backend, " ".join(valid))
        )
    if cap_ofgwrite not in cap_valid:
        bb.fatal(
            "Invalid TUXBOX_FLASH_MACHINE_CAP_OFGWRITE '%s' (valid: %s)"
            % (cap_ofgwrite, " ".join(cap_valid))
        )
    if script_mode not in script_mode_valid:
        bb.fatal(
            "Invalid TUXBOX_FLASH_SCRIPT_MODE '%s' (valid: %s)"
            % (script_mode, " ".join(script_mode_valid))
        )
    if allow_active_slot not in allow_active_slot_valid:
        bb.fatal(
            "Invalid TUXBOX_FLASH_OFGWRITE_ALLOW_ACTIVE_SLOT '%s' (valid: %s)"
            % (allow_active_slot, " ".join(allow_active_slot_valid))
        )
    if active_slot_require_backup not in active_slot_require_backup_valid:
        bb.fatal(
            "Invalid TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_REQUIRE_BACKUP '%s' (valid: %s)"
            % (
                active_slot_require_backup,
                " ".join(active_slot_require_backup_valid),
            )
        )
    if not active_slot_backup_dir:
        bb.fatal("TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_BACKUP_DIR is empty")
    if not active_slot_backup_dir.startswith("/"):
        bb.fatal(
            "TUXBOX_FLASH_OFGWRITE_ACTIVE_SLOT_BACKUP_DIR must be absolute: '%s'"
            % active_slot_backup_dir
        )
    if not script_branch:
        bb.fatal("TUXBOX_FLASH_SCRIPT_GIT_BRANCH is empty")
}
