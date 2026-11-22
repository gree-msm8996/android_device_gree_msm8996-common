# SSC sensors. SLPI firmware is already on the modem partition; these are the
# stock Android 6 userspace pieces plus the HIDL wrapper.

# inherit-product expands PRODUCT_COPY_FILES after every Android.mk has
# overwritten LOCAL_PATH, so keep a private path.
SENSORS_PATH := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

PRODUCT_PACKAGES += \
    sensors.qcom \
    libsensor1 \
    libsensor_reg \
    sensors.ssc \
    sensors.qcom.multihal \
    liblocationservice \
    android.hardware.sensors@1.0-impl \
    android.hardware.sensors@1.0-service

PRODUCT_COPY_FILES += \
    $(SENSORS_PATH)/etc/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/hals.conf

# sensors.qcom daemon reads sensor_def_qcomdev.conf. Its binary only contains
# the fragment "/etc/sensors/" + "sensor_def_" + <board> + ".conf"; stock ships
# the file in /system/etc/sensors/ (reachable via the /etc -> /system/etc
# symlink). Copy it there AND to /vendor/etc/sensors/ so the daemon finds it
# whether it resolves the path absolutely or relative to its exec dir.
PRODUCT_COPY_FILES += \
    $(SENSORS_PATH)/etc/sensor_def_qcomdev.conf:$(TARGET_COPY_OUT_SYSTEM)/etc/sensors/sensor_def_qcomdev.conf \
    $(SENSORS_PATH)/etc/sensor_def_qcomdev.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/sensor_def_qcomdev.conf
