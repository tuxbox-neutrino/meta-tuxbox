HOMEPAGE = "http://www.linuxtv.org"
SUMMARY = "Linux DVB API applications and utilities"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "git://github.com/atvcaptain/dvb-apps.git;protocol=https;branch=master \
           file://0001-dst_test.c-add-missing-defines.patch \
	   file://0001-fix-for-glibc-2.31.patch \
           "

SRCREV = "${AUTOREV}"

PR = "r1"

DEPENDS += "virtual/libiconv"

S = "${WORKDIR}/git"

TARGET_CC_ARCH += "${LDFLAGS}" 

do_configure() {
    sed -i -e s:/usr/include:${STAGING_INCDIR}:g util/av7110_loadkeys/generate-keynames.sh 
}

do_install() {
    make DESTDIR=${D} install
    install -d ${D}/${bindir}
    install -d ${D}/${docdir}/dvb-apps
    install -d ${D}/${docdir}/dvb-apps/scan
    install -d ${D}/${docdir}/dvb-apps/szap
    chmod a+rx ${D}/${libdir}/*.so*

    # Install tests
    install -m 0755 ${S}/test/setvoltage      ${D}${bindir}/test_setvoltage
    install -m 0755 ${S}/test/set22k          ${D}${bindir}/test_set22k
    install -m 0755 ${S}/test/sendburst       ${D}${bindir}/test_sendburst
    install -m 0755 ${S}/test/diseqc          ${D}${bindir}/test_diseqc
    install -m 0755 ${S}/test/test_sections   ${D}${bindir}/
    install -m 0755 ${S}/test/test_av_play    ${D}${bindir}/
    install -m 0755 ${S}/test/test_stillimage ${D}${bindir}/
    install -m 0755 ${S}/test/test_dvr_play   ${D}${bindir}/
    install -m 0755 ${S}/test/test_tt         ${D}${bindir}/
    install -m 0755 ${S}/test/test_sec_ne     ${D}${bindir}/
    install -m 0755 ${S}/test/test_stc        ${D}${bindir}/
    install -m 0755 ${S}/test/test_av         ${D}${bindir}/
    install -m 0755 ${S}/test/test_vevent     ${D}${bindir}/
    install -m 0755 ${S}/test/test_pes        ${D}${bindir}/
    install -m 0755 ${S}/test/test_dvr        ${D}${bindir}/

    cp -pPR ${S}/util/szap/channels-conf* ${D}/${docdir}/dvb-apps/szap/
    cp -pPR ${S}/util/szap/README   ${D}/${docdir}/dvb-apps/szap/
}

python populate_packages:prepend () {
    dvb_libdir = bb.data.expand('${libdir}', d)
    do_split_packages(d, dvb_libdir, '^lib(.*)\.so$', 'lib%s', 'DVB %s package', extra_depends='', allow_links=True)
    do_split_packages(d, dvb_libdir, '^lib(.*)\.la$', 'lib%s-dev', 'DVB %s development package', extra_depends='${PN}-dev')
    do_split_packages(d, dvb_libdir, '^lib(.*)\.a$', 'lib%s-dev', 'DVB %s development package', extra_depends='${PN}-dev')
    do_split_packages(d, dvb_libdir, '^lib(.*)\.so\.*', 'lib%s', 'DVB %s library', extra_depends='', allow_links=True)
}

PACKAGES =+ "dvb-evtest dvb-evtest-dbg \
             dvbapp-tests dvbapp-tests-dbg \
             dvbdate dvbdate-dbg \
             dvbtraffic dvbtraffic-dbg \
             dvbnet dvbnet-dbg \
             dvb-scan dvb-scan-dbg dvb-scan-data \
             dvb-azap dvb-azap-dbg \
             dvb-czap dvb-czap-dbg \
             dvb-szap dvb-szap-dbg \
             dvb-tzap dvb-tzap-dbg \
             dvb-femon dvb-femon-dbg \
             dvb-zap-data"
PACKAGES =+ "libdvbapi libdvbcfg libdvben50221 \
             libesg libucsi libdvbsec"


RDEPENDS:dvbdate =+ "${PN} libdvbapi libucsi"
RDEPENDS:dvbtraffic =+ "${PN} libdvbapi"
RDEPENDS:dvb-scan =+ "${PN} libdvbapi libdvbcfg libdvbsec"
RDEPENDS:${PN} =+ "libdvbapi libdvbcfg libdvbsec libdvben50221 libucsi libesg"
RDEPENDS:dvb-femon =+ "${PN} libdvbapi"
RDEPENDS:dvbnet =+ "${PN} libdvbapi"

FILES:${PN} = "${bindir} ${datadir}/dvb"
FILES:${PN}-doc = ""
FILES:${PN}-dev = "${includedir}"

FILES:dvb-evtest = "${bindir}/evtest"
FILES:dvb-evtest-dbg = "${bindir}/.debug/evtest"
RCONFLICTS:dvb-evtest = "evtest"

FILES:dvbapp-tests = "${bindir}/*test* "
FILES:dvbapp-tests-dbg = "${bindir}/.debug/*test*"

FILES:dvbdate = "${bindir}/dvbdate"
FILES:dvbdate-dbg = "${bindir}/.debug/dvbdate"

FILES:dvbtraffic = "${bindir}/dvbtraffic"
FILES:dvbtraffic-dbg = "${bindir}/.debug/dvbtraffic"

FILES:dvbnet = "${bindir}/dvbnet"
FILES:dvbnet-dbg = "${bindir}/.debug/dvbnet"

FILES:dvb-scan = "${bindir}/*scan "
FILES:dvb-scan-dbg = "${bindir}/.debug/*scan"
FILES:dvb-scan-data = "${docdir}/dvb-apps/scan"

FILES:dvb-azap = "${bindir}/azap"
FILES:dvb-azap-dbg = "${bindir}/.debug/azap"

FILES:dvb-czap = "${bindir}/czap"
FILES:dvb-czap-dbg = "${bindir}/.debug/czap"

FILES:dvb-szap = "${bindir}/szap"
FILES:dvb-szap-dbg = "${bindir}/.debug/szap"

FILES:dvb-tzap = "${bindir}/tzap"
FILES:dvb-tzap-dbg = "${bindir}/.debug/tzap"

FILES:dvb-femon = "${bindir}/femon"
FILES:dvb-femon-dbg = "${bindir}/.debug/femon"

FILES:dvb-zap-data = "${docdir}/dvb-apps/szap"
