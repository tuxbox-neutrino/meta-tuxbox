require ${@'kodi20-src.inc' if d.getVar('PV', '').startswith('20.') else 'kodi19-src.inc'}

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

PR:append = ".6"

SRC_URI:append = " file://0002-kodi-spdlog-no-external-fmt.patch"

# stb builds use GLES; avoid desktop OpenGL requirement.
PACKAGECONFIG:remove = "opengl"
PACKAGECONFIG:append = " openglesv2"

# Keep Enigma2 external player optional (default off).
SRC_URI:append = "${@ ' file://0001-kodi-drop-enigma2player-core.patch;apply=no' if (not bb.utils.contains('DISTRO_FEATURES', 'enigma2', True, False, d) and not bb.utils.contains_any('MACHINE_FEATURES', 'hisil-3798mv200 hisil-3798mv310 hisi hisil', True, False, d)) else '' }"

python do_patch:append() {
    import os
    import subprocess

    patch = os.path.join(d.getVar("WORKDIR"), "0001-kodi-drop-enigma2player-core.patch")
    if not os.path.exists(patch):
        return

    sdir = d.getVar("S")
    cores = os.path.join(sdir, "cmake/treedata/common/cores.txt")
    playercore = os.path.join(sdir, "system/playercorefactory.xml")
    config_h = os.path.join(sdir, "xbmc/cores/playercorefactory/PlayerCoreConfig.h")
    factory_cpp = os.path.join(sdir, "xbmc/cores/playercorefactory/PlayerCoreFactory.cpp")

    def file_contains(path, token):
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as handle:
                return token in handle.read()
        except OSError:
            return False

    if (file_contains(cores, "Enigma2Player") or file_contains(playercore, "E2Player") or
            file_contains(config_h, "Enigma2Player") or file_contains(factory_cpp, "Enigma2Player")):
        bb.note("kodi: dropping Enigma2Player core for non-enigma2 builds")
        with open(patch, "rb") as handle:
            subprocess.check_call(["patch", "-p1", "-N", "-d", sdir], stdin=handle)
