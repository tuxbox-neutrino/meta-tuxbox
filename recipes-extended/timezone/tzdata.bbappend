###
### /etc/localtime is not packaged: Neutrino replaces the link whenever its
### time zone setting is applied, and a link is never a config file, so a
### link in tzdata-core would be written again on every package upgrade.
### The image creates the link from DEFAULT_TIMEZONE in
### tuxbox_rootfs_postprocess (tuxbox-image.inc).
###

PR:append = ".2"

do_install:append () {
	rm ${D}${sysconfdir}/localtime
}
