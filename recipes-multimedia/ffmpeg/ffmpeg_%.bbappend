# Neutrino's pic2m2v (libstb-hal) converts the boot/standby icons to .m2v
# (MPEG-2 elementary video). The oe-alliance ffmpeg config does
# "--disable-encoders" and re-enables only the mpeg1video encoder; mpeg2video
# is enabled there as a *muxer* only, not as an *encoder*. As a result pic2m2v
# fails with "Default encoder for format mpeg2video (codec mpeg2video) is
# probably disabled" and the animations are never generated. Re-enable the
# mpeg2video encoder. EXTRA_FFCONF is the oe-alliance variable consumed by
# EXTRA_OECONF; ":append" applies regardless of bbappend parse order.
EXTRA_FFCONF:append = " --enable-encoder=mpeg2video"

# .2: libbluray moved its soname from .so.3 to .so.4. libavformat58 is the
# only consumer in our images, and it was rebuilt against the new soname
# without a version change - so opkg saw "same version, already installed",
# kept the stale file and left every box with a Neutrino that cannot start
# after the next reboot. Bumping PR is what actually ships the rebuilt
# libraries. Do the same whenever a dependency changes its soname.
PR:append = ".2"
