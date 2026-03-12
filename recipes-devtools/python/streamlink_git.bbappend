# Use the Python-3.13-safe gitpkgv implementation for PKGV generation.
inherit gitpkgv

# Keep Streamlink license checksum in sync with upstream LICENSE updates.
LIC_FILES_CHKSUM = "file://LICENSE;md5=ca97af75b78809a5c401f63ead0f59f2"

# Mark this bbappend revision for feed updates.
PR:append = ".3"

# Override the gittag-based PKGV from oe-alliance streamlink recipe.
PKGV = "${GITPKGVTAG}"

# python3-shell is an empty split package in this setup and no IPK is emitted.
# Keep streamlink installable from feeds by dropping the hard dependency.
RDEPENDS:${PN}:remove = "${PYTHON_PN}-shell"

do_install:append() {
    # Restore CLI module and launcher needed by webtv stream scripts.
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}/streamlink_cli
    if [ -d "${S}/src/streamlink_cli" ]; then
        cp -a ${S}/src/streamlink_cli/. ${D}${PYTHON_SITEPACKAGES_DIR}/streamlink_cli/
    fi

    install -d ${D}${bindir}
    cat >${D}${bindir}/streamlink <<'EOF2'
#!/usr/bin/env python3
from streamlink_cli.main import main

if __name__ == "__main__":
    raise SystemExit(main())
EOF2
    chmod 0755 ${D}${bindir}/streamlink
}

FILES:${PN}:append = " \
    ${bindir}/streamlink \
    ${PYTHON_SITEPACKAGES_DIR}/streamlink_cli \
"
