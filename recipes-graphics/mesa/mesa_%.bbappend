PR:append = ".1"

# Ensure native/nativesdk provide libgbm for SDK helper builds
PROVIDES:append:class-native = " virtual/libgbm-native"
PROVIDES:append:class-nativesdk = " virtual/libgbm-nativesdk"

# Limit egl-native providers to native/nativesdk to avoid provider warnings
PROVIDES:remove:class-target = "virtual/egl-native virtual/nativesdk-egl"
PROVIDES:append:class-native = " virtual/egl-native"
PROVIDES:append:class-nativesdk = " virtual/nativesdk-egl"

# QEMU generic PC needs a software gallium driver and no classic DRI drivers.
DRIDRIVERS:qemux86-64:class-target = ""
DRIDRIVERS:qemux86:class-target = ""
DRIDRIVERS:remove:qemux86-64:class-target = ",r100,r200,nouveau,i965"
DRIDRIVERS:remove:qemux86:class-target = ",r100,r200,nouveau,i965"

PACKAGECONFIG:append:qemux86-64 = " gallium x11"
PACKAGECONFIG:append:qemux86 = " gallium x11"
