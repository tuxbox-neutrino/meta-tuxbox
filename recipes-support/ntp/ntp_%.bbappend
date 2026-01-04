# Ensure the ntp user exists even when only ntpdate is installed.
USERADD_PACKAGES += " ntpdate"
USERADD_PARAM:ntpdate = "--system --home-dir ${NTP_USER_HOME} --no-create-home --shell /bin/false --user-group ntp"
