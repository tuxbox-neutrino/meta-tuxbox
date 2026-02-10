# Tuxbox flash backend capability model
#
# Supported backends:
# - script   : shell-based flash workflow (default)
# - ofgwrite : ofgwrite-based flash workflow

TUXBOX_FLASH_BACKEND_VALID ?= "script ofgwrite"
TUXBOX_FLASH_BACKEND ?= "script"

TUXBOX_FLASH_USES_OFGWRITE = "${@'1' if (d.getVar('TUXBOX_FLASH_BACKEND') or '').strip() == 'ofgwrite' else '0'}"

python __anonymous() {
    backend = (d.getVar("TUXBOX_FLASH_BACKEND") or "").strip()
    valid = (d.getVar("TUXBOX_FLASH_BACKEND_VALID") or "").split()

    if not backend:
        bb.fatal("TUXBOX_FLASH_BACKEND is empty")
    if backend not in valid:
        bb.fatal(
            "Invalid TUXBOX_FLASH_BACKEND '%s' (valid: %s)"
            % (backend, " ".join(valid))
        )
}
