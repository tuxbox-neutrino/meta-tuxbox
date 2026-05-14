# gitlab.xiph.org has been repeatedly unreachable - switching to the official
# xiph GitHub mirror. The source is identical (xiph publishes both).
SRC_URI = "git://github.com/xiph/libao.git;protocol=https;branch=master"

PR:append = ".1"
