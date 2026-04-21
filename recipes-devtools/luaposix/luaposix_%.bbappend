FILESEXTRAPATHS:prepend := "${THISDIR}/luaposix:"

SRC_URI:append = "${@' file://0001-require-bit-for-luajit.patch' if d.getVar('TUXBOX_LUA_PROVIDER') == 'luajit' else ''}"

require recipes-devtools/lua/lua.inc

# Align install paths with luajit (Lua 5.1 compatible)
LUA_VERSION = "${LUA_VER}"

# Use the distro-selected Lua provider instead of the fixed 'lua' dependency
DEPENDS:remove = "lua"
DEPENDS:append = " virtual/lua"

# Build luaposix against the selected Lua provider headers.
# Use lua-native interpreter for build tooling
# (overrides upstream do_compile)
do_compile() {
    ${STAGING_BINDIR_NATIVE}/lua ${S}/build-aux/luke \
        LUAVERSION=${LUA_VERSION} \
        LUA_INCDIR="${TUXBOX_LUA_INCLUDE_DIR}" \
        CFLAGS="-I${TUXBOX_LUA_INCLUDE_DIR}"
}

do_install() {
    ${S}/build-aux/luke PREFIX=${D}${prefix} \
        LUAVERSION=${LUA_VERSION} \
        INST_LIBDIR=${D}${libdir}/lua/${LUA_VERSION} \
        INST_LUADIR=${D}${datadir}/lua/${LUA_VERSION} \
        install
}

PR:append = ".3"
