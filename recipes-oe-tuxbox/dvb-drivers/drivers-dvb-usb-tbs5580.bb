DESCRIPTION = "USB DVB driver bundle for TBS 5580"

require dvb-usb-drivers-meta.inc

# Phase 1 target: bcm7251s based boxes with linux 4.10.12 (hd51/h7 family).
COMPATIBLE_MACHINE = "^(hd51|h7)$"

RRECOMMENDS_${PN} = " \
	tbs-usb-linux-media \
	firmware-dvb-usb-id5580 \
	"

PV = "1.0"
