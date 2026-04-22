CFLAGS:remove = "-I${STAGING_INCDIR}/luajit-2.1"

do_configure:append () {
        sed -i "s|^CFLAGS =.*|CFLAGS = ${CFLAGS} -I${TUXBOX_LUA_INCLUDE_DIR} -fPIC|" ${S}/makefile
}

EXTRA_OEMAKE:append = " 'CFLAGS=${CFLAGS} -I${TUXBOX_LUA_INCLUDE_DIR} -fPIC'"

PR:append = ".2"
