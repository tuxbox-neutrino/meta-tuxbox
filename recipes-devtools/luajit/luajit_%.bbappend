PR:append = ".1"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0008-luajit-add-lua52-compat-typedef.patch"

PROVIDES += "virtual/lua"
RPROVIDES:${PN} += "virtual/lua"
