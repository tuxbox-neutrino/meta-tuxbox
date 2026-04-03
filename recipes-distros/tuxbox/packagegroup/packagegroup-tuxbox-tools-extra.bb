# Packagegroup: Tuxbox Extra Tools
#
# Optional utilities intended for feed install, not for default image size.

DESCRIPTION = "Tuxbox-OS optional extra tools package set"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

RDEPENDS:${PN} = " \
    autofs \
    dvb-apps \
    dvbsnoop \
    evtest \
    f2fs-tools \
    gptfdisk \
    hd-idle \
    iperf3 \
    etckeeper \
    links \
    mc \
    minicom \
    minidlna \
    minisatip \
    openvpn \
    smartmontools \
    streamripper \
    sysstat \
    udpxy \
    ushare \
    vsftpd \
    xfsprogs \
    xupnpd \
"
