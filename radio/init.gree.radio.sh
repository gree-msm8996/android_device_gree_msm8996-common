#!/vendor/bin/sh
# QCRIL 2.x keeps its settings in /data/misc/radio/qcril.db. The stock
# init.qcom.sh seeded it from the prebuilt copy on first boot; do the same.
if [ -f /vendor/qcril.db -a ! -f /data/misc/radio/qcril.db ]; then
    cp /vendor/qcril.db /data/misc/radio/qcril.db
    chown radio.radio /data/misc/radio/qcril.db
    chmod 0660 /data/misc/radio/qcril.db
    restorecon /data/misc/radio/qcril.db 2>/dev/null
fi
echo 1 > /data/misc/radio/db_check_done
chown radio.radio /data/misc/radio/db_check_done
chmod 0660 /data/misc/radio/db_check_done
