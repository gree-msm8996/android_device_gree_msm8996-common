# GNSS blob 来源与 ABI 约定

## vendor/lib64/libdataitems.so

最终文件来自 leeco msm8996-common (G0215D)：

- sha1 `0ff60a5f4273cc3eb9f1f8a4d7bd204107375cec`
- 原始位置：`leeco/vendor_extracted/proprietary_vendor_leeco-lineage-18.1/msm8996-common/proprietary/vendor/lib64/libdataitems.so`

**不能使用 Xiaomi/Gemini MIUI V10.2.2.0 的同名库。** 它按旧版
`NetworkInfoDataItemBase` 布局编译，`NetworkInfoDataItem::copy()` 从
`IDataItemCore*` 的偏移 48/56/80 读取 `mType`/两个 string/bool；而本树源码里
`SystemStatusNetworkInfo` 先继承带两个 `timespec` 的 `SystemStatusItemBase`
（40 字节）再继承 `NetworkInfoDataItemBase`，因此传给 `copy()` 的二级基类指针
对应的字段偏移不同。结果在 `AGnssRil::updateNetworkState()` 触发网络状态通知时，
`basic_string::assign()` 拿到错误指针/长度并抛出 `std::bad_alloc`，GNSS HIDL
service 进程 SIGABRT。

本树已将 `DataItemConcreteTypesBase.h` 的 `NetworkInfoDataItemBase` 布局对齐到
leeco 库（`mAllTypes` / `mAllNetworkHandles[MAX_NETWORK_HANDLES]` /
`mNetworkHandle`），并在 `gps_extended_c.h` 中补齐
`NETWORK_HANDLE_UNKNOWN` / `MAX_NETWORK_HANDLES`。这两处源码改动和上述 blob
是一组 ABI 闭环，必须同进同退。

验证方法：

```bash
adb shell getprop init.svc.gnss_service
adb shell 'ls -lt /data/tombstones'
```

切换网络（Wi-Fi/移动数据）后 `gnss_service` 不应重启，也不应新增
`std::bad_alloc` tombstone。
