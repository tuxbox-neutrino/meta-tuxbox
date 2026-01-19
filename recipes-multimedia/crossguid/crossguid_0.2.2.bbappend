PR:append = ".1"

do_install:append() {
    # Keep legacy install layout if upstream doesn't install these.
    if [ -f ${B}/libxg.a ]; then
        install -D -m 0644 ${B}/libxg.a ${D}${libdir}/libxg.a
    fi
    if [ -f ${S}/Guid.hpp ]; then
        install -D -m 0644 ${S}/Guid.hpp ${D}${includedir}/Guid.hpp
    fi
}
