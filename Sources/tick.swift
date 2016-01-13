
import Glibc


public class Tick {

  // Alias for millis.
  public static var millisecondsSinceEpoch: Int {
    return millis
  }

  public static var millis: Int {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return (ts.tv_sec * 1000) + Int(ts.tv_nsec / 1000000)
  }

}


public class Stopwatch: CustomStringConvertible {

  var startTime: Int = 0

  var sliceTime: Int = 0

  var stopped = true

  // Make the constructor public.
  public init() { }

  public func start() {
    startTime = Tick.millis
    sliceTime = startTime
    stopped = false
  }

  public func stop() {
    doSlice()
    stopped = true
  }

  func doSlice() {
    sliceTime = Tick.millis
  }

  // Alias for millis.
  public var elapsedMilliseconds: Int {
    return millis
  }

  public var millis: Int {
    if (!stopped) {
      doSlice()
    }
    return sliceTime - startTime
  }

  public var description: String {
    return "Stopwatch(startTime: \(startTime), sliceTime: \(sliceTime), " +
        "stopped: \(stopped))"
  }

}
