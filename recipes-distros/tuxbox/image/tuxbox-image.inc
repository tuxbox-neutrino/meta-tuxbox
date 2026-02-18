# Tuxbox-OS Image Base Include
#
# Common image configuration for all Tuxbox-OS image variants

require recipes-core/images/core-image-minimal.bb

LICENSE = "MIT"

# WiFi user-space tools are included by default to support USB sticks.
# Set TUXBOX_WIFI = "0" to disable in local.conf.user.inc.
TUXBOX_WIFI ?= "1"

# Optional parity set for common community image defaults.
# Set TUXBOX_COMMUNITY_PARITY = "1" to enable in local.conf.user.inc.
TUXBOX_COMMUNITY_PARITY ?= "0"

# Image features
IMAGE_FEATURES += " \
    package-management \
    ssh-server-openssh \
    allow-empty-password \
    empty-root-password \
"

# Base packages from packagegroups
IMAGE_INSTALL:append = " \
    packagegroup-tuxbox-base \
    packagegroup-tuxbox-neutrino \
    ${@bb.utils.contains('TUXBOX_WIFI', '1', 'packagegroup-tuxbox-wifi', '', d)} \
    ${@bb.utils.contains('TUXBOX_WIFI', '1', 'packagegroup-tuxbox-wifi-drivers', '', d)} \
    ${@bb.utils.contains('TUXBOX_COMMUNITY_PARITY', '1', 'packagegroup-tuxbox-community-parity', '', d)} \
"

# Multimedia stack
IMAGE_INSTALL:append = " \
    packagegroup-tuxbox-multimedia \
"

# Bootlogo payload for machines that use splash.bin during image packaging.
IMAGE_INSTALL:append = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'bootsplash', 'tuxbox-bootlogo', '', d)} \
"

# System tools
IMAGE_INSTALL:append = " \
    bash \
    htop \
    nano \
    vim-tiny \
    curl \
    cronie \
    wget \
    openssh \
    opkg \
    tuxbox-feed-config \
    less \
    findutils \
    grep \
    procps \
"

# Flash/update tooling must be part of the base image.
IMAGE_INSTALL:append = " \
    flash-script \
    ${@bb.utils.contains('TUXBOX_FLASH_MACHINE_CAP_OFGWRITE', '1', 'ofgwrite', '', d)} \
"

# Networking
IMAGE_INSTALL:append = " \
    packagegroup-tuxbox-network \
"

# Filesystem support
IMAGE_INSTALL:append = " \
    e2fsprogs \
    e2fsprogs-mke2fs \
    e2fsprogs-tune2fs \
    dosfstools \
    ntfs-3g-ntfsprogs \
    exfat-utils \
    parted \
"

# Version file generation
inherit tuxbox-version

# Image size calculation
IMAGE_OVERHEAD_FACTOR ?= "1.3"
IMAGE_ROOTFS_SIZE ?= "262144"
IMAGE_ROOTFS_EXTRA_SPACE ?= "10240"

# Image rootfs post-processing
TUXBOX_SSH_PERSISTENT = "${@'0' if bb.utils.contains('IMAGE_FEATURES', 'read-only-rootfs', True, False, d) or bb.utils.contains('IMAGE_FEATURES', 'stateless-rootfs', True, False, d) else '1'}"

ROOTFS_POSTPROCESS_COMMAND += "tuxbox_rootfs_postprocess; tuxbox_fix_ssh_default; "

tuxbox_rootfs_postprocess() {
    # Set default timezone
    if [ -e ${IMAGE_ROOTFS}${sysconfdir}/timezone ]; then
        echo "${DEFAULT_TIMEZONE}" > ${IMAGE_ROOTFS}${sysconfdir}/timezone
    fi

    # Create standard directories
    install -d ${IMAGE_ROOTFS}/media
    install -d ${IMAGE_ROOTFS}/media/usb
    install -d ${IMAGE_ROOTFS}/media/hdd
    install -d ${IMAGE_ROOTFS}/mnt
    install -d ${IMAGE_ROOTFS}/mnt/nfs

    # Set permissions
    chmod 755 ${IMAGE_ROOTFS}/media
    chmod 755 ${IMAGE_ROOTFS}/mnt
}

tuxbox_fix_ssh_default() {
    if [ "${TUXBOX_SSH_PERSISTENT}" = "1" ]; then
        install -d ${IMAGE_ROOTFS}${sysconfdir}/default
        cat > ${IMAGE_ROOTFS}${sysconfdir}/default/ssh <<'EOF'
SYSCONFDIR=${SYSCONFDIR:-/etc/ssh}
SSHD_OPTS=
EOF
    fi
}

# Image type
IMAGE_FSTYPES += "tar.bz2"

# Optionally create ext4 image for eMMC devices
IMAGE_FSTYPES += "${@bb.utils.contains('MACHINE_FEATURES', 'emmc', 'ext4', '', d)}"

do_package_index[nostamp] = "1"
do_package_index[depends] += "${PACKAGEINDEXDEPS}"

python do_package_index() {
    from oe.rootfs import generate_index_files
    generate_index_files(d)
}
addtask do_package_index after do_rootfs before do_image_complete
