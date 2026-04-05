# Keep signatures deterministic.
#
# Upstream marks do_configure as nostamp, which injects a random UUID taint
# into dependent task hashes and can trigger basehash mismatch errors.
python () {
    d.delVarFlag("do_configure", "nostamp")
}

# deploy artifacts (fastboot.bin etc.) are copied into DEPLOY_DIR_IMAGE which
# lives under TMPDIR.  Exclude do_deploy from sstate so a fresh TMPDIR always
# re-runs the deploy step instead of restoring an empty staging directory.
SSTATE_SKIP_CREATION:task-deploy = "1"
do_deploy[nostamp] = "1"

PR:append = ".2"
