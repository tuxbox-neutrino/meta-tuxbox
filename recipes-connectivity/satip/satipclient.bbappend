PR:append = ".1"

# satip-client 4ae8dd5 carries the oe-alliance ioctl patch upstream now, so it
# no longer applies to current AUTOREV heads and do_patch fails on every arm
# machine. Dropping it changes no numbering here: configure.ac lists h7, hd51
# and hd60 in its VMSG_TYPE2 boxtype test, and _IOC_NONE is 0 on arm, so the
# upstream header picks the same ioctls 11..17 by either route.
#
# oe-alliance-core removed it from the recipe on 5.6 and 6.0; we track 5.1,
# which has not moved since 2023. Drop this once the submodule follows a
# maintained branch.
SRC_URI:remove = "file://0001-auto-detect-and-avoid-ioctl-conflicts.patch"
