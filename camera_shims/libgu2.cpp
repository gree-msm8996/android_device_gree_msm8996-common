/*
 * camera.msm8996.so was built against Android 6's libgui. On this Treble
 * device the HAL runs in the vendor camera-provider process, which talks to
 * /dev/vndbinder where SurfaceFlinger is not registered. Forwarding the
 * Android 6 DisplayEventReceiver constructor to the real Android 11 one
 * therefore blocks forever in "Waiting for service SurfaceFlinger", and
 * stubbing initCheck() to NO_INIT makes QCameraDisplay::vsyncThreadCamera
 * bail out immediately, freezing preview after the first few frames.
 *
 * Instead we synthesise a vsync source: a periodic timerfd (~60 Hz) that the
 * HAL's looper can poll. getEvents drains the timer and emits one Android 6
 * Event {type='vsyn', id, timestamp@offset 8}. The fd is kept in a small
 * registry keyed by the object pointer so we never touch the object memory
 * (the HAL memsets the embedded receiver after construction).
 *
 * The HAL lists this library in place of libgui.so. Symbols it does not
 * define fall through to the real libgui.
 */

#include <stdint.h>
#include <sys/types.h>
#include <sys/timerfd.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>
#include <pthread.h>

namespace android {

class DisplayEventReceiver {
public:
    struct Event {
        uint32_t type;
        uint32_t id;
        int64_t timestamp;
    };

    ssize_t getEvents(Event* events, size_t count);
};

}  // namespace android

using android::DisplayEventReceiver;

namespace {

struct Slot {
    void* obj;
    int fd;
};

Slot g_slots[8];
pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;

int lookup_fd(void* obj) {
    int fd = -1;
    pthread_mutex_lock(&g_lock);
    for (unsigned i = 0; i < sizeof(g_slots) / sizeof(g_slots[0]); ++i) {
        if (g_slots[i].obj == obj) {
            fd = g_slots[i].fd;
            break;
        }
    }
    pthread_mutex_unlock(&g_lock);
    return fd;
}

void store_fd(void* obj, int fd) {
    pthread_mutex_lock(&g_lock);
    for (unsigned i = 0; i < sizeof(g_slots) / sizeof(g_slots[0]); ++i) {
        if (g_slots[i].obj == 0) {
            g_slots[i].obj = obj;
            g_slots[i].fd = fd;
            break;
        }
    }
    pthread_mutex_unlock(&g_lock);
}

void clear_fd(void* obj) {
    pthread_mutex_lock(&g_lock);
    for (unsigned i = 0; i < sizeof(g_slots) / sizeof(g_slots[0]); ++i) {
        if (g_slots[i].obj == obj) {
            g_slots[i].obj = 0;
            g_slots[i].fd = -1;
            break;
        }
    }
    pthread_mutex_unlock(&g_lock);
}

int64_t mono_ns() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000LL + ts.tv_nsec;
}

}  // namespace

extern "C" void _ZN7android20DisplayEventReceiverC1Ev(void* thiz) {
    int fd = timerfd_create(CLOCK_MONOTONIC, TFD_NONBLOCK | TFD_CLOEXEC);
    if (fd >= 0) {
        struct itimerspec ts;
        ts.it_interval.tv_sec = 0;
        ts.it_interval.tv_nsec = 16666667; /* ~60 Hz */
        ts.it_value.tv_sec = 0;
        ts.it_value.tv_nsec = 16666667;
        timerfd_settime(fd, 0, &ts, 0);
    }
    store_fd(thiz, fd);
}

extern "C" void _ZN7android20DisplayEventReceiverD1Ev(void* thiz) {
    int fd = lookup_fd(thiz);
    if (fd >= 0)
        close(fd);
    clear_fd(thiz);
}

extern "C" int _ZNK7android20DisplayEventReceiver9initCheckEv(const void* thiz) {
    return lookup_fd(const_cast<void*>(thiz)) >= 0 ? 0 : -19;
}

extern "C" int _ZNK7android20DisplayEventReceiver5getFdEv(const void* thiz) {
    return lookup_fd(const_cast<void*>(thiz));
}

extern "C" int _ZN7android20DisplayEventReceiver12setVsyncRateEj(void* /*thiz*/,
                                                                unsigned int /*rate*/) {
    return 0;
}

ssize_t DisplayEventReceiver::getEvents(Event* events, size_t count) {
    int fd = lookup_fd(this);
    if (fd < 0 || events == 0 || count == 0)
        return -1;

    uint64_t expirations;
    ssize_t r = read(fd, &expirations, sizeof(expirations));
    if (r != (ssize_t)sizeof(expirations))
        return 0; /* EAGAIN: no pending vsync */

    events->type = 0x7673796e; /* 'vsyn' DISPLAY_EVENT_VSYNC */
    events->id = 0;
    events->timestamp = mono_ns();
    return 1;
}

/*
 * Android 6 android::Parcel is 52 bytes on 32-bit ARM; Android 11 is 60 bytes.
 * camera.msm8996.so allocates two Parcels 52 bytes apart on the stack in
 * QCameraUtils::sendSingleParam and in closeCamera, so constructing the second
 * Parcel corrupts the first and saved registers. Stub the three Parcel methods
 * imported by the HAL and return nullptr from IQService::asInterface so
 * display.qservice transactions become harmless no-ops.
 */
extern "C" void _ZN8qService9IQService11asInterfaceERKN7android2spINS1_7IBinderEEE(
        void** out, const void* /*obj*/) {
    if (out != 0)
        *out = 0;
}

extern "C" void* _ZN7android6ParcelC1Ev(void* self) {
    return self;
}

extern "C" void* _ZN7android6ParcelD1Ev(void* self) {
    return self;
}

extern "C" int _ZN7android6Parcel10writeInt32Ei(void* /*self*/, int /*val*/) {
    return 0;
}