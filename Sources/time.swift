
import Glibc


public typealias CTime = tm

public struct TimeBuffer: CustomStringConvertible {

  public var buffer: CTime
  public var _utc = false

  public init(secondsSinceEpoch: Int) {
    var n = secondsSinceEpoch
    var b = tm()
    localtime_r(&n, &b)
    buffer = b
  }

  public init() {
    self.init(secondsSinceEpoch: time(nil))
  }

  public init(buffer: CTime, utc: Bool = false) {
    self.buffer = buffer
    _utc = utc
  }

  public var isUtc: Bool { return _utc }

  public var isDst: Bool { return buffer.tm_isdst == 1 }

  public var yearday: Int32 { return buffer.tm_yday }

  public var weekday: Int32 { return buffer.tm_wday }

  public var year: Int32 { return buffer.tm_year }

  public var month: Int32 { return buffer.tm_mon }

  public var day: Int32 { return buffer.tm_mday }

  public var hour: Int32 { return buffer.tm_hour }

  public var minute: Int32 { return buffer.tm_min }

  public var second: Int32 { return buffer.tm_sec }

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
        "weekday: \(weekday), yearday: \(yearday), isDst: \(isDst), " +
        "isUtc: \(_utc))"
  }

  static func utc() -> TimeBuffer {
    var n = time(nil)
    var b = tm()
    gmtime_r(&n, &b)
    return TimeBuffer(buffer: b, utc: true)
  }

  static func utc(secondsSinceEpoch: Int) -> TimeBuffer {
    var n = secondsSinceEpoch
    var b = tm()
    gmtime_r(&n, &b)
    return TimeBuffer(buffer: b, utc: true)
  }

}


public struct Time: CustomStringConvertible {

  var _buffer: TimeBuffer
  var _secondsSinceEpoch = 0

  public init() {
    let n = time(nil)
    _secondsSinceEpoch = n
    _buffer = TimeBuffer(secondsSinceEpoch: n)
  }

  public init(secondsSinceEpoch: Int) {
    let n = secondsSinceEpoch - Time.findLocalTimeDifference()
    _secondsSinceEpoch = n
    _buffer = TimeBuffer(secondsSinceEpoch: n)
  }

  public init(buffer: CTime) {
    _buffer = TimeBuffer(buffer: buffer)
    _secondsSinceEpoch = _buffer.secondsSinceEpoch
  }

  public init(buffer: TimeBuffer) {
    _buffer = buffer
    _secondsSinceEpoch = buffer.secondsSinceEpoch
  }

  // Month from 0 to 11.
  public init(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0,
      second: Int = 0) {
    self.init(secondsSinceEpoch: Time.convertToSecondsSinceEpoch(year,
        month: month, day: day, hour: hour, minute: minute, second: second))
  }

  public var isUtc: Bool { return _buffer.isUtc }

  public var isDst: Bool { return _buffer.isDst }

  public var yearday: Int { return Int(_buffer.yearday) }

  public var weekday: Int { return Int(_buffer.weekday) }

  public var year: Int { return 1900 + Int(_buffer.year) }

  public var month: Int { return Int(_buffer.month) }

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
      _secondsSinceEpoch = newValue
      _buffer = TimeBuffer(secondsSinceEpoch: newValue)
    }
  }

  // Returns a new instance of Time.
  // If self is set on UTC already, just copy it over. Otherwise, convert it
  // from local time to UTC.
  public func toUtc() -> Time {
    if isUtc {
      return self
    } else {
      return Time.utc(secondsSinceEpoch: secondsSinceEpoch)
    }
  }

  // Returns a new instance of Time.
  // If self is set on local time already, just copy it over. Otherwise,
  // convert it from UTC to local time.
  public func toLocalTime() -> Time {
    if !isUtc {
      return self
    } else {
      return Time(buffer: TimeBuffer(secondsSinceEpoch: secondsSinceEpoch))
    }
  }

  public var description: String {
    return "Time(year: \(year), month: \(month), day: \(day), " +
        "hour: \(hour), minute: \(minute), second: \(second), " +
        "weekday: \(weekday), yearday: \(yearday), isDst: \(isDst), " +
        "isUtc: \(isUtc))"
  }

  static public func isLeapYear(year: Int) -> Bool {
    if year % 4 != 0 {
      return false
    } else if year % 100 != 0 {
      return true
    } else if year % 400 != 0 {
      return false
    } else {
      return true
    }
  }

  // Months from 0 to 11.
  static public func countYeardays(year: Int, month: Int, day: Int) -> Int {
    var r = day - 1
    switch month {
      case 11: // Dec
        fallthrough
      case 10: // Nov
        r += 30
        fallthrough
      case 9: // Oct
        r += 31
        fallthrough
      case 8: // Sep
        r += 30
        fallthrough
      case 7: // Aug
        r += 31
        fallthrough
      case 6: // Jul
        r += 31
        fallthrough
      case 5: // Jun
        r += 30
        fallthrough
      case 4: // May
        r += 31
        fallthrough
      case 3: // Apr
        r += 30
        fallthrough
      case 2: // Mar
        r += 31
        fallthrough
      case 1: // Feb
        r += isLeapYear(year) ? 29 : 28
        fallthrough
      case 0: // Jan
        r += 31
        fallthrough
      default: // Jan
        () // Ignore.
    }
    return r;
  }

  static public func convertToSecondsSinceEpoch(year: Int, month: Int,
      day: Int, hour: Int, minute: Int, second: Int) -> Int {
    var r = second
    r += minute * 60
    r += hour * 3600
    r += (Time.countYeardays(year, month: month, day: day)) * 86400
    let y = year - 1900
    r += (y - 70) * 31536000
    r += ((y - 69) / 4) * 86400
    return r
  }

  static public func findLocalTimeDifference() -> Int {
    let n = TimeBuffer().secondsSinceEpoch
    let tbUtc = TimeBuffer.utc()
    var nu = tbUtc.secondsSinceEpoch
    // TODO Joao: confirm that this is necessary. The idea is from this SO thread:
    // http://stackoverflow.com/questions/9076494/how-to-convert-from-utc-to-local-time-in-c
    if tbUtc.isDst {
      nu -= 3600
    }
    return n - nu
  }

  static public func utc() -> Time {
    return Time(buffer: TimeBuffer.utc())
  }

  static public func utc(year year: Int, month: Int, day: Int, hour: Int = 0,
      minute: Int = 0, second: Int = 0) -> Time {
    return utc(secondsSinceEpoch: Time.convertToSecondsSinceEpoch(year,
        month: month, day: day, hour: hour, minute: minute, second: second))
  }

  static public func utc(secondsSinceEpoch secs: Int) -> Time {
    return Time(buffer: TimeBuffer.utc(secs))
  }

}
