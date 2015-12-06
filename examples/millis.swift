

import Glibc

var ts: timespec = timespec() //(tv_sec: 0, tv_nsec: 0)

clock_gettime(CLOCK_REALTIME, &ts)

let millis = (ts.tv_sec * 1000) + Int(ts.tv_nsec / 1000000)

print(millis)

sleep(1)

clock_gettime(CLOCK_REALTIME, &ts)

let millis2 = (ts.tv_sec * 1000) + Int(ts.tv_nsec / 1000000)

print(millis2)
