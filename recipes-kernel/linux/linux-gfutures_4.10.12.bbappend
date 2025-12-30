PR:append = ".5"

FILESEXTRAPATHS:prepend := "${THISDIR}/linux-gfutures:"

python do_patch:prepend() {
    import os
    import shutil
    import subprocess

    s = d.getVar("S")
    devtool_tempdir = d.getVar("DEVTOOL_TEMPDIR") or ""

    if devtool_tempdir:
        try:
            if os.path.commonpath([s, devtool_tempdir]) == devtool_tempdir:
                hooks_backup = os.path.join(s, ".git", "hooks.devtool-orig")
                if os.path.isdir(hooks_backup):
                    bb.note("Removing stale devtool hooks backup: %s" % hooks_backup)
                    shutil.rmtree(hooks_backup)

                initial_rev_path = os.path.join(devtool_tempdir, "initial_rev")
                if os.path.isdir(os.path.join(s, ".git")) and os.path.isfile(initial_rev_path):
                    with open(initial_rev_path, "r", encoding="utf-8") as f:
                        initial_rev = f.read().strip()
                    if initial_rev:
                        bb.note("Resetting devtool temp repo to %s" % initial_rev)
                        subprocess.check_call(["git", "-C", s, "reset", "--hard", initial_rev])
                        subprocess.check_call(["git", "-C", s, "clean", "-fdx"])
        except ValueError:
            pass
}

do_configure:prepend() {
    local local_dir="${WORKDIR}/oe-local-files"
    local devtool_dir="${DEVTOOL_TEMPDIR}/oe-local-files"

    for local_dir in "${local_dir}" "${devtool_dir}"; do
        [ -d "${local_dir}" ] || continue
        for name in initramfs-subdirboot.cpio.gz findkerneldevice.sh; do
            if [ ! -e "${WORKDIR}/${name}" ] && [ -e "${local_dir}/${name}" ]; then
                bbnote "Restoring ${name} from ${local_dir}"
                cp -a "${local_dir}/${name}" "${WORKDIR}/${name}"
            fi
        done
    done
}

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
