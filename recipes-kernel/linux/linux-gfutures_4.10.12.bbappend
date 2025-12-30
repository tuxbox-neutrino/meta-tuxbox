do_configure:append() {
    # TODO: Re-enable XFS/i40e after GCC compatibility fixes (patches or older GCC for kernel build).
    if [ -x "${S}/scripts/config" ]; then
        ${S}/scripts/config --file ${B}/.config \
            --disable I40E \
            --disable I40EVF \
            --disable I40E_DCB \
            --disable XFS_FS
        oe_runmake olddefconfig
    else
        bbwarn "scripts/config not found, skipping kernel config tweaks"
    fi
}
