PR:append = ".1"

do_install:append() {
    # Remove empty /lib to avoid installed-vs-shipped QA warnings.
    if [ -d ${D}/lib ] && [ -z "$(ls -A ${D}/lib 2>/dev/null)" ]; then
        rmdir ${D}/lib
    fi
}
