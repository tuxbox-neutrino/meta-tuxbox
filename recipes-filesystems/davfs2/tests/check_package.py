#!/usr/bin/env python3
"""Check the delivered IPK contract without installing or executing target code."""
import argparse
import io
from pathlib import Path
import subprocess
import tarfile

parser = argparse.ArgumentParser()
parser.add_argument('ipk', type=Path)
parser.add_argument('--init', choices=['systemd', 'sysvinit'], required=True)
args = parser.parse_args()


def archive(member):
    return tarfile.open(fileobj=io.BytesIO(subprocess.check_output(['ar', 'p', str(args.ipk), member])), mode='r:*')


with archive('control.tar.gz') as control, archive('data.tar.xz') as data:
    metadata = control.extractfile('./control').read().decode()
    assert 'Version: 1.7.3-r0.1\n' in metadata, metadata
    assert 'Source: davfs2_1.5.4.bb\n' in metadata
    assert 'kernel-module-fuse' in metadata and 'kernel-module-coda' not in metadata
    assert 'util-linux-findmnt' in metadata and 'bash' in metadata
    conffiles = control.extractfile('./conffiles').read().decode().splitlines()
    assert set(conffiles) == {'/etc/davfs2/davfs2.conf', '/etc/davfs2/secrets', '/etc/davfs2/davfs2.mount.list'}
    assert data.getmember('./etc/davfs2/secrets').mode == 0o600
    assert data.getmember('./mnt/dav').isdir()
    paths = {m.name for m in data.getmembers()}
    helper = data.extractfile('./usr/libexec/davfs2/mount-list.sh').read()
    source = Path(__file__).resolve().parents[1] / 'davfs2/mount-list.sh'
    assert helper == source.read_bytes(), 'Packaged helper differs from final workspace'
    for name in ('mount.all.davfs', 'umount.all.davfs', 'mount.davfs', 'umount.davfs'):
        member = data.getmember('./usr/sbin/' + name)
        assert member.mode & 0o111
        if '.all.' in name:
            body = data.extractfile(member).read()
            assert b'@LIBEXECDIR@' not in body
            assert b'/usr/libexec/davfs2/mount-list.sh' in body
    config = data.extractfile('./etc/davfs2/davfs2.conf').read().decode()
    for setting in ('backup_dir      backup', 'use_compression 1', 'use_locks       0'):
        assert setting in config and ('# ' + setting) not in config
    units = [p for p in paths if '/systemd/' in p]
    if args.init == 'systemd':
        unit = data.extractfile('./lib/systemd/system/davfs2.service').read().decode()
        assert 'Wants=network-online.target' in unit and 'After=network-online.target' in unit
        assert 'ExecStopPost=/usr/sbin/umount.all.davfs' in unit
        assert '@SBINPATH@' not in unit
    else:
        assert not units, units
        assert not any('/init.d/' in p for p in paths)
print(f'PASS: {args.init} package {args.ipk}')
