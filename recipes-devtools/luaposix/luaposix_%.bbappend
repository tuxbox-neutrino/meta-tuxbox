FILESEXTRAPATHS:prepend := "${THISDIR}/luaposix:"

SRC_URI:append = " \
    file://0001-require-bit-for-luajit.patch \
"

require recipes-devtools/lua/lua.inc

# Align install paths with luajit (Lua 5.1 compatible)
LUA_VERSION = "${LUA_VER}"

# Use the distro-selected Lua provider instead of the fixed 'lua' dependency
DEPENDS:remove = "lua"
DEPENDS:append = " virtual/lua"

# Build luaposix against luajit headers
# Use lua-native interpreter for build tooling
# (overrides upstream do_compile)
do_compile() {
    ${STAGING_BINDIR_NATIVE}/lua ${S}/build-aux/luke \
        LUAVERSION=${LUA_VERSION} \
        CFLAGS="-I${STAGING_INCDIR}/luajit-2.1"
}

do_install() {
    ${S}/build-aux/luke PREFIX=${D}${prefix} \
        LUAVERSION=${LUA_VERSION} \
        INST_LIBDIR=${D}${libdir}/lua/${LUA_VERSION} \
        INST_LUADIR=${D}${datadir}/lua/${LUA_VERSION} \
        install
}

PR:append = ".1"
