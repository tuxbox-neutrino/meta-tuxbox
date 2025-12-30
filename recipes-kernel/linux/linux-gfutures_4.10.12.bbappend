PR:append = ".2"

do_configure:append() {
    # TODO: Re-enable XFS/i40e after GCC compatibility fixes (patches or older GCC for kernel build).
    if [ -x "${S}/scripts/config" ]; then
        ${S}/scripts/config --file ${B}/.config \
            --disable I40E \
            --disable I40EVF \
            --disable I40E_DCB \
            --disable XFS_FS \
            --disable SCSI_QLA_FC \
            --disable TCM_QLA2XXX \
            --disable SCSI_QLA4XXX \
            --disable SCSI_QLA_ISCSI \
            --disable QLA3XXX \
            --disable VHOST \
            --disable VHOST_NET \
            --disable VHOST_SCSI \
            --disable VHOST_VSOCK \
            --enable CIFS_SMB2
        oe_runmake olddefconfig
    else
        bbwarn "scripts/config not found, skipping kernel config tweaks"
    fi
}
