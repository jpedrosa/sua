
import Glibc


public class TimeStore: CustomStringConvertible {

  public var store: UnsafeMutablePointer<tm>

  public init(store: UnsafeMutablePointer<tm>? = nil) {
    if let v = store {
      self.store = v
    } else {
      var n = time(nil)
      self.store = gmtime(&n)
    }
  }

  public var isDst: Bool { return store.memory.tm_isdst == 1 }

  public var yearday: Int32 { return store.memory.tm_yday }

  public var weekday: Int32 { return store.memory.tm_wday }

  public var year: Int32 { return store.memory.tm_year }

  public var month: Int32 { return store.memory.tm_mon }

  public var day: Int32 { return store.memory.tm_mday }

  public var hour: Int32 { return store.memory.tm_hour }

  public var minutes: Int32 { return store.memory.tm_min }

  public var seconds: Int32 { return store.memory.tm_sec }

  public var description: String {
    return "TimeStore(year: \(year), month: \(month), day: \(day), " +
        "hour: \(hour), minutes: \(minutes), seconds: \(seconds), " +
        "weekday: \(weekday), yearday: \(yearday), isDst: \(isDst))"
  }

}
