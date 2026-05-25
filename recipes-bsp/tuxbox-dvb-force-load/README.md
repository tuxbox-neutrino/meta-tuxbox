# tuxbox-dvb-force-load

Force-loads proprietary DVB driver modules whose modversion CRCs disagree with
the freshly built Kirkstone kernel.

## Why

On the BCM-modversions machines (HD51, H7, Bre2ze4k) Yocto rebuilds the frozen
`4.10.12` vendor kernel with the Kirkstone toolchain (gcc 11). genksyms then
produces different symbol CRCs than the 2019-era proprietary DVB blobs expect.
Because both kernel source and config are unchanged the actual struct layouts
are identical — only the version hash differs, so bypassing the CRC check
(`modprobe --force-modversion`) is safe and matches the
`CONFIG_MODULE_FORCE_LOAD=y` OE-A already enables on these boxes.

Without this workaround `systemd-modules-load.service` fails with
`hd51_1/h7_1/...: disagrees about version of symbol kmem_cache_alloc` and
Neutrino starts without DVB/video.

## What it ships

- `tuxbox-dvb-force-load.service` — oneshot, `Before=systemd-modules-load.service`,
  `WantedBy=sysinit.target`.
- `/usr/sbin/tuxbox-dvb-force-load` — POSIX shell helper.
- `/etc/modules-load.d/tuxbox-dvb-force-load.conf` — marker / future use.

## Behaviour

The helper:

1. Identifies the machine. Primary signal is `/proc/cmdline` (looks for
   `<box>_4.boxmode=` patterns), fallback is `/proc/stb/info/model` and
   `/proc/stb/info/boxtype`. Whitelist today: **`hd51`, `h7`, `bre2ze4k`**. On
   any other model the helper exits 0 immediately.
2. For each supported model, iterates module names listed in
   `/etc/modules-load.d/*.conf` (and after first run also
   `/etc/tuxbox-dvb-force-load.d/*.conf`) and runs
   `modprobe --force-modversion <module>` per entry.
3. After the first successful boot it migrates the proprietary `_*.conf` lists
   (e.g. `_hd51.conf`, `_h7.conf`) out of `/etc/modules-load.d` into
   `/etc/tuxbox-dvb-force-load.d/`, so `systemd-modules-load.service` no longer
   sees them and stops reporting `[FAILED]`.

## First-boot caveat

On the **very first boot after flash** you will still see
`[FAILED] Failed to start Load Kernel Modules` in the journal/serial log.
That is expected: at that point the migration has not happened yet, so
`systemd-modules-load` still finds the proprietary `_*.conf` and fails on the
CRC. The force-loader runs in the same `sysinit.target` phase and brings the
modules up regardless, so Neutrino starts fine. From the second boot onward
the migration has cleared the proprietary entries and the `[FAILED]` is gone.

## Adding a new BCM-modversions box (e.g. E4HDultra)

Both whitelists must be extended in lockstep:

| File | Change |
|---|---|
| `files/tuxbox-dvb-force-load`, `read_model()` cmdline match | add `*" e4hdultra_4.boxmode="*` |
| `files/tuxbox-dvb-force-load`, `is_supported_model()` case | add `e4hdultra` |
| `meta-neutrino` plugin `stb-startup.lua` (`has_bcm_boxmode_quirk()`) | add `or model == "e4hdultra"` |

Without all three edits the box ships unguarded against the modversion skew
and `stb-startup` boxmode toggling will silently no-op.

## Out of scope

- HD60 / multiboxse (Linux 4.4.35) build with `CONFIG_MODVERSIONS=n` and are
  unaffected by the CRC skew; the whitelist makes the helper a no-op on them.
- Pure module signing or vermagic mismatch — only the modversion hash is
  bypassed; vermagic still has to match exactly.

## References

- Workitem `WORK-125` in the agent-kit shared workitems index.
