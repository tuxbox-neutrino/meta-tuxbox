PR:append = ".1"

# The oe-alliance add-missing-keys.patch does not apply to SDL2 2.0.8.
SRC_URI:remove = "file://add-missing-keys.patch"
