FILESEXTRAPATHS:prepend := "${THISDIR}/gfutures-dvb-modules-hd60:"

# Override the vendor suspend script: the upstream variant never reaches
# turnoff_power because of a broken runlevel assignment.
PR:append = ".1"
