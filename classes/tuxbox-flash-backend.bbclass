# Tuxbox flash backend capability model
#
# Supported backends:
# - script   : shell-based flash workflow (default)
# - ofgwrite : ofgwrite-based flash workflow

TUXBOX_FLASH_BACKEND_VALID ?= "script ofgwrite"
TUXBOX_FLASH_BACKEND ?= "script"
TUXBOX_FLASH_MACHINE_CAP_OFGWRITE_VALID ?= "0 1"
TUXBOX_FLASH_MACHINE_CAP_OFGWRITE ?= "${@'0' if (d.getVar('MACHINE') or '').startswith('qemu') else '1'}"

TUXBOX_FLASH_USES_OFGWRITE = "${@'1' if (d.getVar('TUXBOX_FLASH_BACKEND') or '').strip() == 'ofgwrite' else '0'}"

python __anonymous() {
    backend = (d.getVar("TUXBOX_FLASH_BACKEND") or "").strip()
    valid = (d.getVar("TUXBOX_FLASH_BACKEND_VALID") or "").split()
    cap_ofgwrite = (d.getVar("TUXBOX_FLASH_MACHINE_CAP_OFGWRITE") or "").strip()
    cap_valid = (d.getVar("TUXBOX_FLASH_MACHINE_CAP_OFGWRITE_VALID") or "").split()

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
}
