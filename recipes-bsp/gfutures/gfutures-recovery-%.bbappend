# Keep signatures deterministic.
#
# Upstream marks do_configure as nostamp, which injects a random UUID taint
# into dependent task hashes and can trigger basehash mismatch errors.
python () {
    d.delVarFlag("do_configure", "nostamp")
}

PR:append = ".1"
