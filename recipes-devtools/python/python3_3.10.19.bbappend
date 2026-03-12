# Keep bbappend-visible revisioning for feed upgrades.
PR:append = ".1"

# These split packages may be empty in this build setup (modules land in other
# Python subpackages), but several runtime deps still reference the names.
# Emit empty IPKs so opkg can resolve dependency chains consistently.
ALLOW_EMPTY:python3-shell = "1"
ALLOW_EMPTY:python3-mime = "1"
ALLOW_EMPTY:python3-stringold = "1"
ALLOW_EMPTY:python3-netserver = "1"
ALLOW_EMPTY:python3-compression = "1"
