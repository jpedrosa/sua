
import Glibc


public class TimeStore: CustomStringConvertible {

  public var store: UnsafeMutablePointer<tm>

  public init(secondsSinceEpoch: Int) {
    var n = secondsSinceEpoch
    self.store = gmtime(&n)
  }

  public init(store: UnsafeMutablePointer<tm>? = nil) {
    if let v = store {
      self.store = v
    } else {
      var n = time(nil)
      //var brok = gmtime(&n)
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

  public var secondsSinceEpoch: Int {
    var r = Int(seconds)
    r += Int(minutes) * 60
    r += Int(hour) * 3600
    r += Int(yearday) * 86400
    let y = Int(year)
    r += (y - 70) * 31536000
    r += ((y - 69) / 4) * 86400
    //r += ((y - 1) / 100) * 86400
    //r += ((y + 299) / 400) * 86400
    return r
  }

  public var description: String {
    return "TimeStore(year: \(year), month: \(month), day: \(day), " +
        "hour: \(hour), minutes: \(minutes), seconds: \(seconds), " +
        "weekday: \(weekday), yearday: \(yearday), isDst: \(isDst))"
  }

}


public struct TimeMath {

  var _secondsSinceEpoch = 0
  var _store: TimeStore

  public init() {
    self.init(secondsSinceEpoch: time(nil))
  }

  public init(secondsSinceEpoch: Int) {
    var n = secondsSinceEpoch
    _secondsSinceEpoch = n
    _store = TimeStore(store: gmtime(&n))
  }

  public init(store: UnsafeMutablePointer<tm>) {
    _store = TimeStore(store: store)
    _secondsSinceEpoch = _store.secondsSinceEpoch
  }

  public var day: Int {
    get { return Int(_store.day) }
    set {
      secondsSinceEpoch += (newValue - Int(_store.day)) * 86400
    }
  }

  public var hour: Int {
    get { return Int(_store.hour) }
    set {
      secondsSinceEpoch += (newValue - Int(_store.hour)) * 3600
    }
  }

  public var minute: Int {
    get { return Int(_store.minutes) }
    set {
      secondsSinceEpoch += (newValue - Int(_store.minutes)) * 60
    }
  }

  public var second: Int {
    get { return Int(_store.seconds) }
    set {
      secondsSinceEpoch += newValue - Int(_store.seconds)
    }
  }

  public var secondsSinceEpoch: Int {
    get { return _secondsSinceEpoch }
    set {
      var n = newValue
      _secondsSinceEpoch = n
      _store = TimeStore(store: gmtime(&n))
    }
  }

  public var store: TimeStore {
    return _store
  }

}
