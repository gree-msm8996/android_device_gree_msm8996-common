# Gree telephony: the Qualcomm modem stack (QCRIL 2.x, QMI, DSI/netmgr,
# CNE/IMS) from the leeco msm8996-common (G0215D) vendor set. The 18.1
# rild/libril (HIDL, CAF style) loads libril-qc-qmi-1.so from that set.
#
# Layout rule: every *blob* of the radio stack lives in
# vendor/gree/msm8996-common/proprietary/, is declared in
# device/gree/msm8996-common/proprietary-files.txt with its source, and is
# installed by the generated vendor makefile. This directory only keeps what
# is authored here: the init script, the rc file and the libperipheral_client
# source. That way a blob never has two possible sources and the vendor tree
# stays the single place that mirrors the device.
#
# qmuxd stays stock G0245D (no leeco copy exists) because the leeco RILD and
# netmgrd still talk over /dev/socket/qmux_radio (their binaries reference
# qcril_radio_config* and use_qmuxd). pm-service is disabled: every client
# opens /dev/subsys_modem through libperipheral_client built here.

RADIO_PATH := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

# peripheral_client talks to /dev/subsys_modem; it is built from source here
# (radio/libperipheral_client) because no stock copy exists in the dump.
PRODUCT_PACKAGES += \
    libperipheral_client

PRODUCT_COPY_FILES += \
    $(RADIO_PATH)/init.gree.radio.sh:$(TARGET_COPY_OUT_VENDOR)/bin/init.gree.radio.sh \
    $(RADIO_PATH)/vendor.gree.radio.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/vendor.gree.radio.rc \
    $(RADIO_PATH)/mcfg/ct_openmkt_volte.mbn:$(TARGET_COPY_OUT_VENDOR)/etc/mcfg/ct_openmkt_volte.mbn

# CT VoLTE: enable the RIL mbn_sw feature so qcril scans
# /data/vendor/radio/modem_config, builds the mbn index in qcril.db and
# activates the config matching the SIM (see init.qcom.sh for the install).
# Without sw_mbn_update=1 the feature logs "Feature disabled" and the modem
# keeps its stale EFS config, leaving IMS permanently off.
PRODUCT_PROPERTY_OVERRIDES += \
    persist.vendor.radio.sw_mbn_update=1 \
    persist.vendor.radio.sw_mbn_volte=1

# Stock build.prop values that the Android 6 QCRIL and the data stack read by
# their non-vendor names ("persist.radio.*", not "persist.vendor.radio.*").
# Values already present in vendor_prop.mk are not repeated here.
PRODUCT_PROPERTY_OVERRIDES += \
    persist.radio.calls.on.ims=0 \
    persist.radio.csvt.enabled=false \
    persist.radio.custom_ecc=1 \
    persist.radio.jbims=0 \
    persist.radio.mt_sms_ack=20 \
    persist.radio.rat_on=combine \
    persist.radio.relay_oprt_change=1 \
    persist.radio.sib16_support=1 \
    persist.radio.start_ota_daemon=1 \
    persist.rild.nitz_plmn= \
    persist.rild.nitz_long_ons_0= \
    persist.rild.nitz_long_ons_1= \
    persist.rild.nitz_long_ons_2= \
    persist.rild.nitz_long_ons_3= \
    persist.rild.nitz_short_ons_0= \
    persist.rild.nitz_short_ons_1= \
    persist.rild.nitz_short_ons_2= \
    persist.rild.nitz_short_ons_3= \
    persist.cne.feature=1 \
    persist.net.doxlat=true \
    persist.sys.ssr.restart_level=related
