PR:append = ".2"

# Current upstream libaacs already tries pkg-config before falling back to
# libgcrypt-config/gpg-error-config. The older OE-Alliance patch no longer
# applies to current AUTOREV heads, so keep the recipe on the upstream checks.
SRC_URI:remove = "file://libgcrypt-gpg-error-use-pkgconfig.patch"
