FILESEXTRAPATHS:prepend := "${OEA-META-GFUTURES-BASE}/recipes-linux/linux-gfutures-${PV}/${MACHINE}:"

# linux-gfutures_4.4.35 ships defconfigs only for hisil boxes (hd60/hd61/hd66se).
# Avoid parse-time errors on other machines by only adding defconfig for those.
SRC_URI:remove = "file://defconfig"
SRC_URI:append:hd60 = " file://defconfig"
SRC_URI:append:hd61 = " file://defconfig"
SRC_URI:append:hd66se = " file://defconfig"
