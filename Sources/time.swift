
import Glibc


public struct TimeBuffer: CustomStringConvertible {

  public var buffer: UnsafeMutablePointer<tm>

  public init(secondsSinceEpoch: Int) {
    var n = secondsSinceEpoch
    self.buffer = gmtime(&n)
  }

  public init() {
    var n = time(nil)
    self.buffer = gmtime(&n)
  }

  public init(buffer: UnsafeMutablePointer<tm>) {
    self.buffer = buffer
  }

  public var isDst: Bool { return buffer.memory.tm_isdst == 1 }

  public var yearday: Int32 { return buffer.memory.tm_yday }

  public var weekday: Int32 { return buffer.memory.tm_wday }

  public var year: Int32 { return buffer.memory.tm_year }

  public var month: Int32 { return buffer.memory.tm_mon }

  public var day: Int32 { return buffer.memory.tm_mday }

  public var hour: Int32 { return buffer.memory.tm_hour }

  public var minute: Int32 { return buffer.memory.tm_min }

  public var second: Int32 { return buffer.memory.tm_sec }

  public var secondsSinceEpoch: Int {
    var r = Int(second)
    r += Int(minute) * 60
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
    return "TimeBuffer(year: \(year), month: \(month), day: \(day), " +
        "hour: \(hour), minute: \(minute), second: \(second), " +
        "weekday: \(weekday), yearday: \(yearday), isDst: \(isDst))"
  }

}


public struct TimeMath {

  var _secondsSinceEpoch = 0
  var _buffer: TimeBuffer

  public init() {
    self.init(secondsSinceEpoch: time(nil))
  }

  public init(secondsSinceEpoch: Int) {
    var n = secondsSinceEpoch
    _secondsSinceEpoch = n
    _buffer = TimeBuffer(buffer: gmtime(&n))
  }

  public init(buffer: UnsafeMutablePointer<tm>) {
    _buffer = TimeBuffer(buffer: buffer)
    _secondsSinceEpoch = _buffer.secondsSinceEpoch
  }

  public var day: Int {
    get { return Int(_buffer.day) }
    set {
      secondsSinceEpoch += (newValue - Int(_buffer.day)) * 86400
    }
  }

  public var hour: Int {
    get { return Int(_buffer.hour) }
    set {
      secondsSinceEpoch += (newValue - Int(_buffer.hour)) * 3600
    }
  }

  public var minute: Int {
    get { return Int(_buffer.minute) }
    set {
      secondsSinceEpoch += (newValue - Int(_buffer.minute)) * 60
    }
  }

  public var second: Int {
    get { return Int(_buffer.second) }
    set {
      secondsSinceEpoch += newValue - Int(_buffer.second)
    }
  }

  public var secondsSinceEpoch: Int {
    get { return _secondsSinceEpoch }
    set {
      var n = newValue
      _secondsSinceEpoch = n
      _buffer = TimeBuffer(buffer: gmtime(&n))
    }
  }

  public var buffer: TimeBuffer {
    return _buffer
  }

}


public struct Time {

  public init() {

  }

}
