
import Glibc


class Stopwatch {

  var startTime: timespec = timespec()

  var sliceTime: timespec = timespec()

  var stopped = false

  init() {
    startTime = timespec();
  }

  func start() {
    clock_gettime(CLOCK_REALTIME, &startTime)
    stopped = false
  }

  func stop() {
    doSlice()
    stopped = true
  }

  func doSlice() {
    clock_gettime(CLOCK_REALTIME, &sliceTime)
  }

  var elapsedInMilliseconds: Int {
    get {
      let st = (startTime.tv_sec * 1000) + Int(startTime.tv_nsec / 1000000)
      if (!stopped) {
        doSlice()
      }
      let et = (sliceTime.tv_sec * 1000) + Int(sliceTime.tv_nsec / 1000000)
      return et - st
    }
  }

}

var sw = Stopwatch()

sw.start()
sleep(1)
sw.stop()
print("Elapsed: \(sw.elapsedInMilliseconds)")
sw.start()
sleep(2)
print("Elapsed: \(sw.elapsedInMilliseconds)")
sleep(3)
print("Elapsed: \(sw.elapsedInMilliseconds)")
