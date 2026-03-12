# Keep bbappend-visible revisioning for feed upgrades.
PR:append = ".1"

# Native ssl in Python/OpenSSL is sufficient for our streamlink runtime.
# Avoid hard deps that trigger unnecessary crypto/rust-heavy chains.
RDEPENDS:${PN}:remove = " \
    ${PYTHON_PN}-cryptography \
    ${PYTHON_PN}-pyopenssl \
"
