# sensors 目录 blobs 来源与重做方法

这些 blob 是 G0245D stock 的 64 位 SSC/sensors 栈，放到设备树是为了避免
vendor 的 32 位同名库和 Android 11 通用 QMI 库干扰。vendor 中保留的
`vendor/lib/libsensor1.so`、`libsensor_reg.so`、`sensors.ssc.so` 是 32 位变体，
没有安装路径冲突，仍由 `proprietary-files.txt` 保留。

## bin/sensors.qcom

最终文件：`bin/sensors.qcom`，md5 `506a052ff6aa74d45c27e1ddb337e90f`。

输入基线：`work/sensor-rollback/sensors.qcom`，
md5 `3539b6a7bd6e5b2f6fb0461f42e59cb7`（未打补丁 stock daemon）。

修改方法：给 ELF 动态段增加
`DT_RUNPATH=/system/vendor/lib64/sensors_qcci`，可用 patchelf/LIEF 等价方式完成。
原因：`sensors.qcom` 以 setuid 启动，`AT_SECURE=1`，bionic 忽略 init.rc 的
`LD_LIBRARY_PATH`；若没有 RUNPATH，会加载 Android 11 的 `/vendor/lib64/libqmi_cci.so`
并在 `sns_sam_init` 卡死。私有 QMI 库来自 vendor/gree：
`msm8996-common/proprietary/vendor/lib64/sensors_qcci/libqmi_cci.so`。

验证：

```bash
readelf -d device/gree/msm8996-common/sensors/bin/sensors.qcom | grep RUNPATH
```

必须显示 `/system/vendor/lib64/sensors_qcci`。

## 未修改的 stock blobs

以下文件按 G0245D stock 原样放入设备树，未做二进制补丁：

| 文件 | md5 |
| --- | --- |
| `lib64/hw/sensors.qcom.so` | `dd00eb7935742e205482b25ec98db2bd` |
| `lib64/libsensor1.so` | `1753993b4e2d169335d5401ef9692781` |
| `lib64/libsensor_reg.so` | `dfffffc5715f49491f610781b6ef0db7` |
| `lib64/sensors.ssc.so` | `3eb622d1b630cefd096a04b395fda36a` |

`work/sensor-rollback/` 下有同样四个文件的 stock 副本，可作为二次处理输入。
