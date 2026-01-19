PR:append = ".1"

# Upstream switched to Meson; autotools no longer produces a Makefile.
inherit meson

EXTRA_OEMESON += " \
    -Dbdj_jar=disabled \
    -Denable_docs=false \
    -Dfontconfig=disabled \
    -Dfreetype=disabled \
"
