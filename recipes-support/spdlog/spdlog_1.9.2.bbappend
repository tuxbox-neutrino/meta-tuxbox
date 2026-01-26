# Use bundled fmt to avoid external fmt version mismatches.
PR:append = ".1"

SRC_URI:remove = "file://0001-Enable-use-of-external-fmt-library.patch"

EXTRA_OECMAKE:remove = "-DSPDLOG_FMT_EXTERNAL=on"
EXTRA_OECMAKE:append = " -DSPDLOG_FMT_EXTERNAL=off -DSPDLOG_FMT_EXTERNAL_HO=off"
