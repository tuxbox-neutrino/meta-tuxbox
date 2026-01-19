PR:append = ".1"

# Avoid AUTOREV network lookups and GitLab 503s by pinning to GitHub.
SRC_URI = "git://github.com/BYVoid/uchardet.git;protocol=https;branch=master"
SRCREV = "4e685757780cb3c652fc6c9ec759f62888969ec9"
