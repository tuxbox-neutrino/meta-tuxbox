# Packagegroup: Tuxbox Network
#
# Network services and tools

DESCRIPTION = "Tuxbox-OS network packages"
LICENSE = "MIT"
PR = "r2"

inherit packagegroup

RDEPENDS:${PN} = " \
    busybox-udhcpc \
    ifupdown \
    openssh \
    openssh-sftp-server \
    samba \
    nfs-utils \
    nfs-utils-client \
    avahi-daemon \
    avahi-utils \
    ethtool \
    iputils-ping \
    iproute2 \
    iptables \
    tcpdump \
"
#    samba \  # Temporarily disabled due to postinst bash syntax issues

RRECOMMENDS:${PN} = " \
    wget \
    curl \
    rsync \
"
