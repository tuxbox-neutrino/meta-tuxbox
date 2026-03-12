# Keep bbappend-visible revisioning for feed upgrades.
PR:append = ".1"

# cssselect is optional for streamlink use-cases and not required by lxml
# itself at runtime.
RDEPENDS:${PN}:remove = " ${PYTHON_PN}-cssselect"
