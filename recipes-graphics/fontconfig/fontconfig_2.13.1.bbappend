# Ensure uuid headers are available in the native sysroot during test builds.
DEPENDS:append = " util-linux-libuuid"

# test-hash includes <uuid/uuid.h>, so ensure the native include root is on the path.
CPPFLAGS:append:class-native = " -I${STAGING_INCDIR_NATIVE}"
CFLAGS:append:class-native = " -I${STAGING_INCDIR_NATIVE}"
