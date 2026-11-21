/*
 * Historically this preloaded library stubbed the Android 6
 * DisplayEventReceiver constructor. The synthetic vsync source now lives in
 * libgu2 (which the HAL links in place of libgui), including the constructor,
 * so this library intentionally defines no symbols. It remains in the build
 * and LD_PRELOAD list as a harmless placeholder.
 */