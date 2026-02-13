FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://telnetd.cfg \
			   file://dos2unix.cfg \
			   file://ether-wake.cfg \
			   file://remove.cfg \
			   file://simple.script \
			   file://ash.cfg \
			   file://wget.cfg \
			   file://ftpd.cfg \
			   file://profile \
"

BUSYBOX_SPLIT_SUID = "0"

# Drop the default /etc/resolv.conf shipped by busybox to let systemd
# manage the symlink without update-alternatives errors.
PR:append = ".2"

do_install:append() {
    install -m644 ${WORKDIR}/profile ${D}${sysconfdir}
    rm -f ${D}${sysconfdir}/resolv.conf

    if [ -f ${D}${sysconfdir}/profile ]; then
        if ! grep -q "tuxbox-prompt" ${D}${sysconfdir}/profile; then
            cat >> ${D}${sysconfdir}/profile <<'EOF'

# tuxbox-prompt
case "$-" in
    *i*) PS1='\u@\h:\w\$ ' ;;
esac

if [ -d /etc/profile.d ]; then
    for i in /etc/profile.d/*.sh; do
        if [ -f "$i" -a -r "$i" ]; then
            . "$i"
        fi
    done
    unset i
fi
EOF
        fi
    fi
}
