CFLAGS:remove = "-I${STAGING_INCDIR}/luajit-2.1"
CFLAGS:append = " -I${TUXBOX_LUA_INCLUDE_DIR}"

PR:append = ".1"
