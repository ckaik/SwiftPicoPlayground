/*
 * Compatibility shims for Embedded Swift Concurrency on bare-metal RP2xxx.
 *
 * These symbols are required by libswift_Concurrency and
 * libswift_ConcurrencyDefaultExecutor for async entry points, but are not
 * fully provided by the default embedded toolchain + Pico SDK link.
 */

#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

extern uint64_t time_us_64(void);

typedef struct {
  void *identity;
  uintptr_t witnessAndFlags;
} SwiftExecutorRef;

static uintptr_t packWitness(const void *witnessTable) {
  return ((uintptr_t)witnessTable) | (uintptr_t)1U;
}

void *swift_getObjectType(void *object) {
  if (object == NULL) {
    return NULL;
  }

  return *(void **)object;
}

int _task_serialExecutor_checkIsolated(
  void *executor, const void *executorType, const void *witnessTable
) {
  (void)executor;
  (void)executorType;
  (void)witnessTable;
  return 1;
}

signed char _task_serialExecutor_isIsolatingCurrentContext(
  void *executor, const void *executorType, const void *witnessTable
) {
  (void)executor;
  (void)executorType;
  (void)witnessTable;
  return 1;
}

int _task_serialExecutor_isSameExclusiveExecutionContext(
  const void *leftExecutor,
  const void *rightExecutor,
  const void *rightExecutorType,
  const void *witnessTable
) {
  (void)rightExecutorType;
  (void)witnessTable;
  return leftExecutor == rightExecutor;
}

SwiftExecutorRef _task_serialExecutor_getExecutorRef(
  void *executor, const void *executorType, const void *witnessTable
) {
  (void)executorType;
  return (SwiftExecutorRef) {
    .identity = executor,
    .witnessAndFlags = packWitness(witnessTable),
  };
}

SwiftExecutorRef _task_taskExecutor_getTaskExecutorRef(
  void *executor, const void *executorType, const void *witnessTable
) {
  (void)executorType;
  return (SwiftExecutorRef) {
    .identity = executor,
    .witnessAndFlags = packWitness(witnessTable),
  };
}

int memset_s(void *dest, size_t destMax, int ch, size_t count) {
  if (dest == NULL || destMax == 0) {
    errno = EINVAL;
    return EINVAL;
  }

  size_t bytesToWrite = count;
  int status = 0;
  if (bytesToWrite > destMax) {
    bytesToWrite = destMax;
    status = ERANGE;
  }

  (void)memset(dest, ch, bytesToWrite);

  if (status != 0) {
    errno = status;
  }

  return status;
}

static int64_t monotonicNanoseconds(void) {
  return (int64_t)time_us_64() * 1000LL;
}

int clock_getres(int clockId, struct timespec *res) {
  (void)clockId;
  if (res == NULL) {
    errno = EINVAL;
    return -1;
  }

  res->tv_sec = 0;
  res->tv_nsec = 1000;
  return 0;
}

int clock_gettime(int clockId, struct timespec *tp) {
  (void)clockId;
  if (tp == NULL) {
    errno = EINVAL;
    return -1;
  }

  uint64_t micros = time_us_64();
  tp->tv_sec = (time_t)(micros / 1000000ULL);
  tp->tv_nsec = (long)((micros % 1000000ULL) * 1000ULL);
  return 0;
}

static int validateTimespec(const struct timespec *value) {
  if (value == NULL) {
    return 0;
  }
  if (value->tv_sec < 0) {
    return 0;
  }
  if (value->tv_nsec < 0 || value->tv_nsec >= 1000000000L) {
    return 0;
  }
  return 1;
}

int _nanosleep(const struct timespec *requested, struct timespec *remaining) {
  if (!validateTimespec(requested)) {
    errno = EINVAL;
    return -1;
  }

  if (remaining != NULL) {
    remaining->tv_sec = 0;
    remaining->tv_nsec = 0;
  }

  uint64_t delayNs = ((uint64_t)requested->tv_sec * 1000000000ULL)
    + (uint64_t)requested->tv_nsec;
  uint64_t delayUs = delayNs / 1000ULL;
  if ((delayNs % 1000ULL) != 0) {
    delayUs += 1ULL;
  }

  uint64_t start = time_us_64();
  uint64_t deadline = start + delayUs;
  while (time_us_64() < deadline) {}

  return 0;
}

int *__error(void) {
  return &errno;
}

int _fputs(const char *text, void *stream) {
  (void)stream;

  if (text == NULL) {
    errno = EINVAL;
    return EOF;
  }

  while (*text != '\0') {
    if (putchar((unsigned char)*text) == EOF) {
      return EOF;
    }
    text += 1;
  }

  return 0;
}

static void *gStderrStream = NULL;
void **__stderrp = &gStderrStream;

typedef struct {
  int64_t nanoseconds;
} SteadyClockTimePoint;

SteadyClockTimePoint swiftChronoSteadyClockNow(void)
  __asm__("_ZNSt3__16chrono12steady_clock3nowEv");
SteadyClockTimePoint swiftChronoSteadyClockNow(void) {
  SteadyClockTimePoint value;
  value.nanoseconds = monotonicNanoseconds();
  return value;
}
