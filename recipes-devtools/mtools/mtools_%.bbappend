# Ensure RDEPENDS on glibc-gconv-* has a build-time provider.
PR:append = ".5"
DEPENDS:append:class-target:libc-glibc = " glibc glibc-locale"
