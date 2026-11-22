#!/vendor/bin/sh
# Copyright (c) 2009-2016, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Set shared buttons and touchpanel nodes ownership (these are proc_symlinks to the real sysfs nodes)
chown -LR system.system /proc/buttons
chown -LR system.system /proc/touchpanel

#
# Make modem config folder and copy firmware config to that folder for RIL
#
if [ -f /data/vendor/radio/ver_info.txt ]; then
    prev_version_info=`cat /data/vendor/radio/ver_info.txt`
else
    prev_version_info=""
fi

cur_version_info=`cat /vendor/firmware_mnt/verinfo/ver_info.txt`
if [ ! -f /vendor/firmware_mnt/verinfo/ver_info.txt -o "$prev_version_info" != "$cur_version_info" ]; then
    # add W for group recursively before delete
    chmod g+w -R /data/vendor/modem_config/*
    rm -rf /data/vendor/modem_config/*
    # preserve the read only mode for all subdir and files
    cp --preserve=m -dr /vendor/firmware_mnt/image/modem_pr/mcfg/configs/* /data/vendor/modem_config
    cp --preserve=m -d /vendor/firmware_mnt/verinfo/ver_info.txt /data/vendor/modem_config/
    cp --preserve=m -d /vendor/firmware_mnt/image/modem_pr/mbn_ota.txt /data/vendor/modem_config/
    # the group must be root, otherwise this script could not add "W" for group recursively
    chown -hR radio.root /data/vendor/modem_config/*
fi
chmod g-w /data/vendor/modem_config
setprop ro.vendor.ril.mbn_copy_completed 1

#
# CT VoLTE: the stock G0245D modem ships no VoLTE-capable mcfg for China
# Telecom (46011). RIL's mbn_sw feature (libril-qc-qmi-1) scans the hardcoded
# directory /data/vendor/radio/modem_config/mcfg_sw, indexes every mcfg into
# qcril.db and activates the one matching (MCC,MNC,VOLTE,OPENMKT,COMMERC).
# We therefore point that directory at the copy made above and install a
# patched CT "openmkt" mcfg whose trailer metadata says VOLTE + PLMN 460-11
# (content NVs are the CU_VoLTE set: IMS_enable=1, ims_operation_mode=2).
# The mbn ELF hash segment (ph1) carries the SHA256 of the config segment, so
# the shipped file is pre-patched and re-hashed; editing it by hand without
# recomputing that hash makes the modem reject the PDC upload.
#
if [ ! -e /data/vendor/radio/modem_config ]; then
    ln -s /data/vendor/modem_config /data/vendor/radio/modem_config
fi
volte_mcfg=/vendor/etc/mcfg/ct_openmkt_volte.mbn
volte_dst=/data/vendor/modem_config/mcfg_sw/generic/china/ct/commerci/openmkt/mcfg_sw.mbn
if [ -f "$volte_mcfg" ] && [ -f "$volte_dst" ] && ! cmp -s "$volte_mcfg" "$volte_dst"; then
    cat "$volte_mcfg" > "$volte_dst"
    chown radio.root "$volte_dst"
    chmod 0440 "$volte_dst"
    # qcril.db caches the mbn metadata of the previous scan; force a rescan
    # so the patched config is indexed before the mbn_sw flow runs.
    rm -f /data/vendor/radio/qcril.db /data/vendor/radio/qcril_backup.db
    setprop persist.vendor.radio.sw_mbn_loaded 0
fi

# Check build variant for printk logging
# Current default minimum boot-time-default
buildvariant=`getprop ro.build.type`
case "$buildvariant" in
    "userdebug" | "eng")
        #set default loglevel to KERN_INFO
        echo "6 6 1 7" > /proc/sys/kernel/printk
        ;;
    *)
        #set default loglevel to KERN_WARNING
        echo "4 4 1 4" > /proc/sys/kernel/printk
        ;;
esac
