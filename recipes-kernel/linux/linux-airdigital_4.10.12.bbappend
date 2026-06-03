FILESEXTRAPATHS:prepend := "${THISDIR}/linux-airdigital-4.10.12:"

# Override selected upstream kernel patches with refreshed variants to
# avoid patch-fuzz QA warnings on linux-airdigital 4.10.12.
SRC_URI:append = " file://0002-dvb-core-dmxdev-guard-null-feed-priv.patch"

PR:append = ".2"
