# Use the tuxbox-neutrino maintained fork to keep flash behavior branding-free
# and aligned with active-slot flashing requirements.
SRC_URI = "git://github.com/tuxbox-neutrino/ofgwrite.git;protocol=https;branch=master"
SRCREV = "12830ef0183d96eacda7fc0494022ea63ace8b02"
DEPENDS:append = " openssl"
CFLAGS:append = " -Wno-error=format-security"

PR:append = ".1"
