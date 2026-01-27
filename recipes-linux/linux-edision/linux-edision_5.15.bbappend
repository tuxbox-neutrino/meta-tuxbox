EDISION_DEFCONFIG_DIR = "${@os.path.join((d.getVar('OEA-META-EDISION-BASE') or ''), 'recipes-linux', 'linux-edision-5.15', (d.getVar('MACHINE') or ''))}"
FILESEXTRAPATHS:prepend := "${EDISION_DEFCONFIG_DIR}:"

PR:append = ".1"
