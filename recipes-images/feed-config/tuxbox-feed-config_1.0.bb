DESCRIPTION = "Tuxbox image feed configuration"
# derived from poky-feed-config
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
PR = "r3"
PACKAGE_ARCH = "${MACHINE_ARCH}"
INHIBIT_DEFAULT_DEPS = "1"

DEPENDS = "opkg"

IPK_FEED_SERVER ?= ""
FEED_DEPLOYDIR_BASE_URI ?= ""

do_compile () {
	# Create a new directory with the path ${S}/${sysconfdir}/opkg/, if not exists.
	mkdir -p ${S}/${sysconfdir}/opkg/

	# Set variable basefeedconf to the path ${S}/${sysconfdir}/opkg/base-feeds.conf.
	basefeedconf=${S}/${sysconfdir}/opkg/base-feeds.conf

	# Remove the file at path $basefeedconf if it exists, and then create an empty file at the same path.
	: > "$basefeedconf"

	feed_uri="${IPK_FEED_SERVER}"
	if [ -z "$feed_uri" ] && [ -n "${FEED_DEPLOYDIR_BASE_URI}" ]; then
		feed_uri="${FEED_DEPLOYDIR_BASE_URI}"
	fi

	# If IPK_FEED_SERVER or FEED_DEPLOYDIR_BASE_URI is set, append a few lines of
	# comments to $basefeedconf. Otherwise add a hint on how to configure feeds.
	if [ -n "$feed_uri" ]; then
		echo "# URI prefix '${feed_uri}'" >> $basefeedconf
		echo "# is set by IPK_FEED_SERVER or FEED_DEPLOYDIR_BASE_URI." >> $basefeedconf
		echo "# Architectures are derived from deploy/ipk when available." >> $basefeedconf
		echo "# Otherwise, a fallback arch list is used." >> $basefeedconf
	else
		echo "# set the IPK_FEED_SERVER or FEED_DEPLOYDIR_BASE_URI variable during build to" >> $basefeedconf
		echo "# configure real feeds here." >> $basefeedconf
	fi
	echo "#" >> "$basefeedconf"

	# Use the find command to locate all subdirectories in ${DEPLOY_DIR_IPK} that
	# contain packages. Fall back to standard archs if the deploy dir is empty.
	# For each arch, construct a feed URI and append a line with the format
	# src/gz FNAME URI.
	ipkgarchs=""
	if [ -d "${DEPLOY_DIR_IPK}" ]; then
		ipkgarchs=$(find ${DEPLOY_DIR_IPK} -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
	fi
	if [ -z "$ipkgarchs" ]; then
		ipkgarchs="all ${PACKAGE_EXTRA_ARCHS} ${MACHINE_ARCH}"
	fi
	for arch in $ipkgarchs; do
# 		if [[ $arch == "any" || $arch == "noarch" ]]; then
# 			continue
# 		fi
		FNAME="$arch"
		if [ -n "$feed_uri" ]; then
			URI="${feed_uri}/$arch"
			printf "src/gz\t$FNAME\t$URI\n" >> "$basefeedconf"
		fi
	done

	# Set the variable H to the current hostname, and set BUILD_DIR to the base name of the directory ${TOPDIR}.
	# Use the sed command to replace instances of @hostname@ and @build-dirname@ in the file at path $basefeedconf with the values of H and BUILD_DIR, respectively. 
	# NOTE: If the user has provided a custom URL or IP address using
	# IPK_FEED_SERVER or FEED_DEPLOYDIR_BASE_URI, the placeholders have no effect.
	H=$(hostname)
	BUILD_DIR=$(basename ${TOPDIR})
	sed -i -e "s|@hostname@|${H}|g" "$basefeedconf"
	sed -i -e "s|@build-dirname@|${BUILD_DIR}|g" "$basefeedconf"
}

do_install () {
	install -d ${D}${sysconfdir}/opkg
	install -m 0644  ${S}/${sysconfdir}/opkg/* ${D}${sysconfdir}/opkg/
}

FILES_${PN} = "${sysconfdir}/opkg/"

CONFFILES_${PN} += "${sysconfdir}/opkg/base-feeds.conf"
