#define MG_ARCH MG_ARCH_PICOSDK
// Pre-define MG_OTA_PICOSDK so the guard at mongoose.h:342 evaluates
// correctly (otherwise both sides are 0 and the #if passes).
#define MG_OTA_PICOSDK 920
#define MG_OTA 0
#define MG_ENABLE_SSI 0
#define MG_ENABLE_POSIX_FS 0
#define MG_ENABLE_PACKED_FS 0
#define MG_ENABLE_FATFS 0
#define MG_ENABLE_LINES 0
#define MG_IO_SIZE 1024

// Use Mongoose's built-in TCP/IP stack with the CYW43 Pico W driver.
// lwIP socket mode (MG_ENABLE_LWIP) is not viable because CPicoSDK
// ships with LWIP_SOCKET=0 and cannot provide <lwip/sockets.h>.
#define MG_ENABLE_LWIP 0
#define MG_ENABLE_TCPIP 1
#define MG_ENABLE_DRIVER_PICO_W 1
#define MG_ENABLE_SOCKET 0
