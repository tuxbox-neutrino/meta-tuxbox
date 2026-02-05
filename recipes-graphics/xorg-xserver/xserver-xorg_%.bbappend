PR:append = ".1"

# QEMU uses a minimal Xorg setup; avoid glamor to drop the libgbm dependency
# from oe-alliance's mesa changes.
PACKAGECONFIG:remove:qemux86-64 = "glamor dri3"
PACKAGECONFIG:remove:qemux86 = "glamor dri3"
