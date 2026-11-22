LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := lights.c
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_SHARED_LIBRARIES := liblog libcutils
LOCAL_HEADER_LIBRARIES := libhardware_headers
# Unique module name (hardware/qcom-caf/msm8996/display/liblight also defines
# lights.msm8996, and LOCAL_MODULE_STEM is not allowed for shared libraries).
# Installed as hw/lights.gree.so; selected by ro.hardware.lights=gree in
# msm8996.mk (hw_get_module checks that property first).
LOCAL_MODULE := lights.gree
LOCAL_MODULE_TAGS := optional
LOCAL_VENDOR_MODULE := true
include $(BUILD_SHARED_LIBRARY)
