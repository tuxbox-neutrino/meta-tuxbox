# Non-fastboot multiboot platforms still need the standalone startup switcher.
# Fastboot platforms already receive it through `neutrino-lua-stb-plugins`.
PR:append = ".1"

RDEPENDS:${PN}:append = " ${@'stb-startup' if ((d.getVar('TUXBOX_STARTUP_SWITCH_CAPABLE') or '0') == '1' and not bb.utils.contains('MACHINE_FEATURES', 'fastboot', True, False, d)) else ''}"
