# camera_shims 说明

本目录的 C/C++ 源码用于替代 stock Android 6 camera HAL 在 Android 11 上缺失的边界层：

- `libgu2.cpp` → `libgu2.so`：由 `Android.bp` 编译，替换 HAL 的 `DT_NEEDED libgui.so`，
  合成 vsync 并 stub Android 6 Parcel/IQService 布局。
- `libshim_camera.c` → `libshim_camera.so`：由 `Android.bp` 编译，作为 provider
  覆盖用的空 `LD_PRELOAD` 占位。vendor/gree 中旧的 `libshim_camera.so` 已删除，
  `msm8996-common/proprietary-files.txt` 中对应条目也已移除。

以下两个源码仅作为 stock blob 的源参考，当前构建仍从 vendor/gree 安装对应二进制；
不要删除 vendor 中的 blobs，否则 camera 会失去必要依赖：

- `libshim_metadata.cpp` → vendor blob `vendor/lib/libshim_metadata.so`
- `libshim_mutex.c` → vendor blob `vendor/lib/libshim_mutex.so`

其中 `libshim_mutex.so` 还被 `device/gree/g0245d/camera/mm-qcamera-daemon` 以
`DT_NEEDED` 方式强制加载。
