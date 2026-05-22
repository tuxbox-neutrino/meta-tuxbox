# Upstream yt-dlp moved to pyproject/hatchling, while the OE-A recipe still
# inherits setuptools3. Build and ship yt-dlp's standalone zipapp entrypoint.

PR:append = ".1"

do_compile() {
	cd ${S}
	oe_runmake lazy-extractors yt-dlp completion-bash
	sed -i -e '1s|^#!.*$|#!/usr/bin/python3|' ${S}/yt-dlp
}

do_install() {
	install -d ${D}${bindir}
	install -m 0755 ${S}/yt-dlp ${D}${bindir}/yt-dlp

	install -d ${D}${sysconfdir}/bash_completion.d
	install -m 0644 ${S}/completions/bash/yt-dlp ${D}${sysconfdir}/bash_completion.d/yt-dlp.bash-completion
}

RDEPENDS:${PN} = " \
	${PYTHON_PN}-core \
	${PYTHON_PN}-compression \
	${PYTHON_PN}-crypt \
	${PYTHON_PN}-ctypes \
	${PYTHON_PN}-datetime \
	${PYTHON_PN}-email \
	${PYTHON_PN}-html \
	${PYTHON_PN}-io \
	${PYTHON_PN}-json \
	${PYTHON_PN}-logging \
	${PYTHON_PN}-math \
	${PYTHON_PN}-netclient \
	${PYTHON_PN}-numbers \
	${PYTHON_PN}-pickle \
	${PYTHON_PN}-shell \
	${PYTHON_PN}-stringold \
	${PYTHON_PN}-threading \
	${PYTHON_PN}-unixadmin \
	${PYTHON_PN}-xml \
"

RDEPENDS:${PN}-src = "${PN}"

FILES:${PN} = " \
	${bindir}/yt-dlp \
	${sysconfdir}/bash_completion.d/yt-dlp.bash-completion \
"
