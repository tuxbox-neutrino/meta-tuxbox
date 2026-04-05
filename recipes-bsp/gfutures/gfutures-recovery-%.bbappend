# Keep signatures deterministic.
#
# Upstream marks do_configure as nostamp, which injects a random UUID taint
# into dependent task hashes and can trigger basehash mismatch errors.
python () {
    d.delVarFlag("do_configure", "nostamp")
}

# Deploy artifacts live under TMPDIR.  Force re-deploy after tmp cleanup
# instead of restoring an empty sstate staging directory.
SSTATE_SKIP_CREATION:task-deploy = "1"
do_deploy[nostamp] = "1"

PR:append = ".2"
