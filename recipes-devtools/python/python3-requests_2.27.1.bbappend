# Keep bbappend-visible revisioning for feed upgrades.
PR:append = ".1"

# Streamlink only needs the core requests functionality.
# Drop legacy TLS extras that pull in heavy transitive stacks.
RDEPENDS:${PN}:remove = " \
    ${PYTHON_PN}-ndg-httpsclient \
    ${PYTHON_PN}-pyasn1 \
    ${PYTHON_PN}-pyopenssl \
"
