SUMMARY = "Extentions for zsh"
DESCRIPTION = "Zsh is a shell designed for interactive use, although it is also a \
               powerful scripting language. Many of the useful features of bash, \
               ksh, and tcsh were incorporated into zsh; many original features were added."
HOMEPAGE = "https://github.com/robbyrussell/oh-my-zsh.git"
SECTION = "base/shell"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=a3d89f44b0b29ba4bd48cf7cf62bc9c3"

RDEPENDS:${PN} = "zsh"

SRC_URI = "git://github.com/robbyrussell/oh-my-zsh.git;protocol=https;branch=master \
	   file://zshrc \
"

SRCREV = "852a44094a3bb4df39f8f778bc7ada2ddda09727"
PV = "${SRCPV}"
PR = "2"

S = "${WORKDIR}/git"

do_install () {
	install -d ${D}/home/root/.oh-my-zsh ${D}${sysconfdir}/zsh
	cp -rf ${S}/* ${D}/home/root/.oh-my-zsh
	cp -rf ${WORKDIR}/zshrc ${D}${sysconfdir}/zsh/zshrc
}

FILES:${PN} = "/home \
	       /etc \
"
