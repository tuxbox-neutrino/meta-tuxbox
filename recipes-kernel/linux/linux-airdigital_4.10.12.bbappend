FILESEXTRAPATHS:prepend := "${THISDIR}/linux-airdigital-4.10.12:"

# Override selected upstream kernel patches with refreshed variants to
# avoid patch-fuzz QA warnings on linux-airdigital 4.10.12.
PR:append = ".1"
