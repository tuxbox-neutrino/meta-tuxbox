LUA_VER = "5.1"

TUXBOX_LUA_PKGCONFIG = "${@'luajit' if d.getVar('TUXBOX_LUA_PROVIDER') == 'luajit' else 'lua'}"
TUXBOX_LUA_INCLUDE_DIR = "${@'%s/luajit-2.1' % d.getVar('STAGING_INCDIR') if d.getVar('TUXBOX_LUA_PROVIDER') == 'luajit' else d.getVar('STAGING_INCDIR')}"
