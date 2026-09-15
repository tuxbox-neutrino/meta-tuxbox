#!/usr/bin/env python3
"""Lifecycle contract tests; all mount-related commands are isolated stubs."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

HELPER = Path(__file__).resolve().parents[1] / 'davfs2/mount-list.sh'
MOCK = '''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['CALLS'], 'a') as f:
    f.write(json.dumps([name, args]) + '\\n')
if name == 'findmnt':
    if os.environ.get('TABLE_FAIL'):
        sys.exit(2)
    if '--mountpoint' not in args:
        print('/')
        sys.exit(0)
    point = args[args.index('--mountpoint') + 1]
    value = json.loads(os.environ.get('MOUNTS', '{}')).get(point)
    if value:
        print(value)
        sys.exit(0)
    sys.exit(1)
if name == 'curl' and args[-1] in json.loads(os.environ.get('UNREACHABLE_URLS', '[]')):
    sys.exit(7)
if name in ('mount.davfs', 'umount', 'mkdir'):
    # A child cannot consume subsequent mount-list entries or prompt a user.
    if name != 'mkdir':
        assert sys.stdin.read() == ''
    if name != 'mkdir' and args[-1] in json.loads(os.environ.get('FAIL_POINTS', '[]')):
        print('SENSITIVE-COMMAND-OUTPUT', file=sys.stderr)
        sys.exit(7)
sys.exit(0)
'''


class MountListTests(unittest.TestCase):
    def run_case(self, content, action='mount', mounts=None, fail=(),
                 table_fail=False, unreachable=()):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in ('curl', 'findmnt', 'mkdir', 'mount.davfs', 'umount'):
                p = root / name
                p.write_text(MOCK)
                p.chmod(0o755)
            config = root / 'list'
            if content is not None:
                config.write_text(content)
            calls = root / 'calls'
            env = dict(os.environ, PATH=f'{root}:' + os.environ['PATH'],
                       CALLS=str(calls), MOUNTS=json.dumps(mounts or {}),
                       FAIL_POINTS=json.dumps(list(fail)),
                       UNREACHABLE_URLS=json.dumps(list(unreachable)))
            if table_fail:
                env['TABLE_FAIL'] = '1'
            result = subprocess.run(['bash', '-c', 'source "$1"; davfs_run "$2" "$3"',
                                     'test', str(HELPER), action, str(config)],
                                    env=env, text=True, capture_output=True)
            recorded = [json.loads(x) for x in calls.read_text().splitlines()] if calls.exists() else []
            self.assertNotIn('SENSITIVE-COMMAND-OUTPUT', result.stdout + result.stderr)
            return result, [(name, args) for name, args in recorded if name in ('mount.davfs', 'umount')]

    def test_empty_and_comments(self):
        p, calls = self.run_case('\n # indented\n\t# comment\n')
        self.assertEqual(p.returncode, 0)
        self.assertEqual(calls, [])

    def test_multiple_and_unterminated_last_line(self):
        p, calls = self.run_case('https://example/a /mnt/a\nhttps://example/b /mnt/b')
        self.assertEqual(p.returncode, 0)
        self.assertEqual(len(calls), 2)
        self.assertIn('2 completed', p.stdout)

    def test_partial_failure_continues(self):
        p, calls = self.run_case('https://example/a /mnt/a\nhttps://example/b /mnt/b\n', fail=['/mnt/a'])
        self.assertEqual(p.returncode, 1)
        self.assertEqual(len(calls), 2)
        self.assertIn('1 completed, 0 skipped, 1 failed', p.stdout)

    def test_unreachable_server_is_rejected_before_mount(self):
        p, calls = self.run_case('https://example/a /mnt/a\n',
                                 unreachable=['https://example/a'])
        self.assertEqual(p.returncode, 1)
        self.assertEqual(calls, [])
        self.assertIn('WebDAV server is not reachable', p.stderr)

    def test_existing_correct_mount_is_skipped(self):
        p, calls = self.run_case('https://example/a /mnt/a\n', mounts={'/mnt/a': 'https://example/a fuse.davfs'})
        self.assertEqual(p.returncode, 0)
        self.assertEqual(calls, [])
        self.assertIn('1 skipped', p.stdout)

    def test_upstream_kernel_fuse_type(self):
        for action in ('mount', 'umount'):
            p, calls = self.run_case('https://example/a /mnt/a\n', action,
                                    {'/mnt/a': 'https://example/a fuse'})
            self.assertEqual(p.returncode, 0)
            self.assertEqual(len(calls), 0 if action == 'mount' else 1)

    def test_foreign_mounts_untouched(self):
        for action in ('mount', 'umount'):
            for mount in ('https://other/a fuse.davfs', 'https://example/a ext4'):
                with self.subTest(action=action, mount=mount):
                    p, calls = self.run_case('https://example/a /mnt/a\n', action, {'/mnt/a': mount})
                    self.assertEqual(p.returncode, 1)
                    self.assertEqual(calls, [])

    def test_unmount_only_listed_matching_mounts(self):
        p, calls = self.run_case('https://example/a /mnt/a\n', 'umount',
                                {'/mnt/a': 'https://example/a fuse.davfs', '/mnt/manual': 'https://manual fuse.davfs'})
        self.assertEqual(p.returncode, 0)
        self.assertEqual(calls, [('umount', ['--', '/mnt/a'])])
        self.assertIn('1 completed', p.stdout)

    def test_unmount_failure_and_missing_mount(self):
        p, calls = self.run_case('https://example/a /mnt/a\nhttps://example/b /mnt/b\n', 'umount',
                                {'/mnt/a': 'https://example/a fuse.davfs'}, ['/mnt/a'])
        self.assertEqual(p.returncode, 1)
        self.assertEqual(len(calls), 1)
        self.assertIn('0 completed, 1 skipped, 1 failed', p.stdout)

    def test_invalid_entries_and_legacy_certificate_option(self):
        for entry in ('https://example/a /mnt/a ignore_cert', 'ftp://example /mnt/a',
                      'https:///a /mnt/a', 'https://example relative',
                      'https://example /', 'https://example /mnt/a extra',
                      'https://user:secret@example /mnt/a', 'https://example /mnt/../a',
                      'https://example /mnt/a\r'):
            with self.subTest(entry=entry):
                p, calls = self.run_case(entry + '\n')
                self.assertEqual(p.returncode, 1)
                self.assertEqual(calls, [])
                self.assertNotIn('secret@example', p.stdout + p.stderr)
                if 'ignore_cert' in entry:
                    self.assertIn('trust_server_cert', p.stderr)

    def test_literal_shell_characters(self):
        p, calls = self.run_case('https://example/a?x=* /mnt/$(literal)*\n')
        self.assertEqual(p.returncode, 0)
        self.assertEqual(calls, [('mount.davfs', ['https://example/a?x=*', '/mnt/$(literal)*'])])

    def test_stacked_mounts_are_untouched(self):
        p, calls = self.run_case('https://example/a /mnt/a\n', 'umount',
                                {'/mnt/a': 'https://example/a fuse\nhttps://other fuse'})
        self.assertEqual(p.returncode, 1)
        self.assertEqual(calls, [])

    def test_missing_config_and_unavailable_mount_table(self):
        for content, table_fail in ((None, False), ('https://example /mnt/a\n', True)):
            p, calls = self.run_case(content, table_fail=table_fail)
            self.assertEqual(p.returncode, 1)
            self.assertEqual(calls, [])


if __name__ == '__main__':
    unittest.main()
