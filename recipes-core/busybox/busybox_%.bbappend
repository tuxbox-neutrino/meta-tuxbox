# Drop the default /etc/resolv.conf shipped by busybox to let systemd
# manage the symlink without update-alternatives errors.
PR:append = ".1"

do_install:append() {
    rm -f ${D}${sysconfdir}/resolv.conf
    # Drop unused systemd unit files to silence installed-vs-shipped QA
    rm -f ${D}${systemd_unitdir}/system/ftpd.service
    rm -f ${D}${systemd_unitdir}/system/telnet.service
    rm -rf ${D}${systemd_unitdir}/system/multi-user.target.wants

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
