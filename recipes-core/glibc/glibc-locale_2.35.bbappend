# Make glibc-locale robust when the binary locale stash is absent
# (ENABLE_BINARY_LOCALE_GENERATION=0). Ensure target dirs exist and
# fall back to a stub SUPPORTED file instead of failing.
PR:append = ".6"

# Align locale stash path with glibc PACKAGE_ARCH (glibc is MACHINE_ARCH).
python __anonymous() {
    import os
    pkgarch = d.getVar("PACKAGE_ARCH")
    macharch = d.getVar("MACHINE_ARCH")
    if pkgarch and macharch and pkgarch != macharch:
        components = d.getVar("COMPONENTS_DIR")
        d.setVar("LOCALETREESRC", os.path.join(components, macharch, "glibc-stash-locale"))
}
do_install() {
    copy_locale_files ${bindir} 0755
    copy_locale_files ${localedir} 0644
    if [ ${PACKAGE_NO_GCONV} -eq 0 ]; then
        copy_locale_files ${libdir}/gconv 0755
        copy_locale_files ${datadir}/i18n 0644
    fi
    # Remove empty dirs in libdir when gconv or locales are not copied
    if [ -d ${D}${libdir} ]; then
        find ${D}${libdir} -type d -empty -delete || true
    fi
    if [ -d ${D}${localedir} ]; then
        find ${D}${localedir} -type d -empty -delete || true
        rmdir --ignore-fail-on-non-empty ${D}${localedir} || true
    fi
    rmdir --ignore-fail-on-non-empty ${D}${libdir} || true
    rmdir --ignore-fail-on-non-empty ${D}${prefix} || true
    copy_locale_files ${datadir}/locale 0644

    if [ -f ${LOCALETREESRC}/SUPPORTED ]; then
        install -m 0644 ${LOCALETREESRC}/SUPPORTED ${WORKDIR}/SUPPORTED
    else
        bbnote "glibc-locale: ${LOCALETREESRC}/SUPPORTED missing; installing stub"
        install -d ${WORKDIR}
        echo "# stub SUPPORTED; binary locale stash missing" > ${WORKDIR}/SUPPORTED
    fi
}

# Skip binary-locale staging cleanly when the stash is absent to avoid tar errors
do_prep_locale_tree() {
    treedir=${WORKDIR}/locale-tree
    rm -rf $treedir
    rm -f ${WORKDIR}/locale-tree.skip
    if [ ! -d "${LOCALETREESRC}${datadir}/i18n" ]; then
        bbnote "glibc-locale: skipping prep_locale_tree; ${LOCALETREESRC}${datadir}/i18n missing"
        touch ${WORKDIR}/locale-tree.skip
        return 0
    fi

    mkdir -p $treedir/${base_bindir} $treedir/${base_libdir} $treedir/${datadir} $treedir/${localedir}
    tar -cf - -C ${LOCALETREESRC}${datadir} -p i18n | tar -xf - -C $treedir/${datadir}
    # unzip to avoid parsing errors
    for i in $treedir/${datadir}/i18n/charmaps/*gz; do
        [ -e "$i" ] || continue
        gunzip "$i"
    done
    # The extract pattern "./l*.so*" is carefully selected so that it will
    # match ld*.so and lib*.so*, but not any files in the gconv directory
    # (if it exists). This makes sure we only unpack the files we need.
    # This is important in case usrmerge is set in DISTRO_FEATURES, which
    # means ${base_libdir} == ${libdir}.
    tar -cf - -C ${LOCALETREESRC}${base_libdir} -p . | tar -xf - -C $treedir/${base_libdir} --wildcards './l*.so*'
    if [ -f ${STAGING_LIBDIR_NATIVE}/libgcc_s.* ]; then
        tar -cf - -C ${STAGING_LIBDIR_NATIVE} -p libgcc_s.* | tar -xf - -C $treedir/${base_libdir}
    fi
    install -m 0755 ${LOCALETREESRC}${bindir}/localedef $treedir/${base_bindir}
}

do_collect_bins_from_locale_tree() {
    if [ -f ${WORKDIR}/locale-tree.skip ]; then
        bbnote "glibc-locale: skipping collect_bins_from_locale_tree; locale tree not prepared"
        return 0
    fi

    treedir=${WORKDIR}/locale-tree
    parent=$(dirname ${localedir})
    mkdir -p ${PKGD}/$parent
    tar -cf - -C $treedir/$parent -p $(basename ${localedir}) | tar -xf - -C ${PKGD}$parent

    # Finalize tree by changing all duplicate files into hard links.
    cross-localedef-hardlink -c -v ${WORKDIR}/locale-tree
}
