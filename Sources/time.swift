

// This class holds a buffer to C's tm (CTime) struct. The tm struct is
// needed for retrieving data from C functions such as localtime_r and gmtime_r.
// This is a low level class that still exposes many of the C level interfaces.
public struct TimeBuffer: CustomStringConvertible {

  public var buffer: CTime
  public var _utc = false

  public init(secondsSinceEpoch: Int) {
    var b = Sys.timeBuffer()
    Sys.localtime_r(secondsSinceEpoch, buffer: &b)
    buffer = b
  }

  public init() {
    self.init(secondsSinceEpoch: Sys.time())
  }

  public init(buffer: CTime, utc: Bool = false) {
    self.buffer = buffer
    _utc = utc
  }

  public var isUtc: Bool { return _utc }

  public var isDst: Bool { return buffer.tm_isdst == 1 }

  public var yearday: Int32 { return buffer.tm_yday }

  // Low level. C-based. Weekdays start from 0 with Sunday.
  public var weekday: Int32 { return buffer.tm_wday }

  // Low level. C-based. Years start from 1900.
  // Current year would have a value of current_year - 1900.
  // E.g. 2016 - 1900   // Which would be 116.
  public var year: Int32 { return buffer.tm_year }

  // Low level. C-based. Months go from 0 to 11 here.
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
    return r
  }

  public var description: String {
    return "TimeBuffer(year: \(year), month: \(month), day: \(day), " +
        "hour: \(hour), minute: \(minute), second: \(second), " +
        "weekday: \(weekday), yearday: \(yearday), isDst: \(isDst), " +
        "isUtc: \(_utc))"
  }

  static func utc() -> TimeBuffer {
    var b = Sys.timeBuffer()
    Sys.gmtime_r(Sys.time(), buffer: &b)
    return TimeBuffer(buffer: b, utc: true)
  }

  static func utc(secondsSinceEpoch secondsSinceEpoch: Int) -> TimeBuffer {
    var b = Sys.timeBuffer()
    Sys.gmtime_r(secondsSinceEpoch, buffer: &b)
    return TimeBuffer(buffer: b, utc: true)
  }

}


// Time is by default set on local time. It also supports time in UTC format
// and can convert between the two of them with methods such as toUtc() and
// toLocalTime().
//
// Time math is supported on the second, minute, hour and day properties and
// a new time buffer value will be computed to present the changes with.
//
// Time can also be compared with the comparison operators: <  ==  >  !=
//
// An output format can be obtained by using the strftime function similar to C.
// E.g.
//    var t = Time()           // Creates a new Time object set on local time.
//    var u = Time.utc()       // Creates a new Time object set on UTC time.
//    print(Time().strftime("%Y-%m-%d %H:%M:%S")) //> 2015-12-29 05:28:20
//    print(Time() == Time())  // Prints true
//    print(Time().secondsSinceEpoch) // Prints 1451377821
//    var k = Time(year: 2016, month: 12, day: 30) // Creates a new Time object.
//    // As does this:
//    Time.utc(year: 2016, month: 12, day: 30, hour: 5, minute: 3, second: 1)
//    var r = Time()
//    r.minute -= 30           // Goes back in time half an hour.
//    r.day += 7               // Goes forward a week.
public struct Time: CustomStringConvertible {

  var _buffer: TimeBuffer
  var _secondsSinceEpoch = 0

  // This property is still under consideration. It may be useful when using
  // the strftime command to include milliseconds, which nanoseconds are then
  // converted to. It may also help to store all the time data that is
  // available under Linux.
  public var nanoseconds = 0

  public init() {
    self.init(secondsSinceEpoch: Sys.time())
  }

  // Assume secondsSinceEpoch is coming from UTC.
  public init(secondsSinceEpoch: Int, nanoseconds: Int = 0) {
    _secondsSinceEpoch = secondsSinceEpoch
    self.nanoseconds = nanoseconds
    _buffer = TimeBuffer(secondsSinceEpoch: secondsSinceEpoch)
  }

  public init(buffer: CTime) {
    _buffer = TimeBuffer(buffer: buffer)
    _secondsSinceEpoch = _buffer.secondsSinceEpoch
  }

  public init(buffer: TimeBuffer) {
    _buffer = buffer
    _secondsSinceEpoch = buffer.secondsSinceEpoch
  }

  public init(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0,
      second: Int = 0) {
    self.init(secondsSinceEpoch: Time.convertToSecondsSinceEpoch(year,
        month: month, day: day, hour: hour, minute: minute, second: second) -
        Time.findLocalTimeDifference())
  }

  public var isUtc: Bool { return _buffer.isUtc }

  public var isDst: Bool { return _buffer.isDst }

  public var yearday: Int { return Int(_buffer.yearday) }

  // Make it range from Monday to Sunday and from 1 to 7.
  public var weekday: Int {
    let n = Int(_buffer.weekday)
    return n == 0 ? 7 : n
  }

  public var year: Int { return 1900 + Int(_buffer.year) }

  public var month: Int { return 1 + Int(_buffer.month) }

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
      return Time.utc(secondsSinceEpoch: secondsSinceEpoch,
          nanoseconds: nanoseconds)
    }
  }

  // Returns a new instance of Time.
  // If self is set on local time already, just copy it over. Otherwise,
  // convert it from UTC to local time.
  public func toLocalTime() -> Time {
    if !isUtc {
      return self
    } else {
      return Time(secondsSinceEpoch: secondsSinceEpoch,
          nanoseconds: nanoseconds)
    }
  }

  public func strftime(mask: String) -> String {
    return Time.locale.strftime(self, mask: mask)
  }

  public var description: String {
    return "Time(year: \(year), month: \(month), day: \(day), " +
        "hour: \(hour), minute: \(minute), second: \(second), " +
        "nanoseconds: \(nanoseconds), weekday: \(weekday), " +
        "yearday: \(yearday), isDst: \(isDst), isUtc: \(isUtc))"
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

  static public func countYeardays(year: Int, month: Int, day: Int) -> Int {
    var r = day - 1
    switch month {
      case 12: // Dec
        fallthrough
      case 11: // Nov
        r += 30
        fallthrough
      case 10: // Oct
        r += 31
        fallthrough
      case 9: // Sep
        r += 30
        fallthrough
      case 8: // Aug
        r += 31
        fallthrough
      case 7: // Jul
        r += 31
        fallthrough
      case 6: // Jun
        r += 30
        fallthrough
      case 5: // May
        r += 31
        fallthrough
      case 4: // Apr
        r += 30
        fallthrough
      case 3: // Mar
        r += 31
        fallthrough
      case 2: // Feb
        r += isLeapYear(year) ? 29 : 28
        fallthrough
      case 1: // Jan
        r += 31
        fallthrough
      default:
        () // Ignore.
    }
    return r;
  }

  static public func convertToSecondsSinceEpoch(year: Int, month: Int,
      day: Int, hour: Int, minute: Int, second: Int) -> Int {
    var r = second
    r += minute * 60
    r += hour * 3600
    r += countYeardays(year, month: month, day: day) * 86400
    let y = year - 1900
    r += (y - 70) * 31536000
    r += ((y - 69) / 4) * 86400
    return r
  }

  static public func findLocalTimeDifference() -> Int {
    let n = TimeBuffer().secondsSinceEpoch
    let tbUtc = TimeBuffer.utc()
    var nu = tbUtc.secondsSinceEpoch
    // TODO Joao: confirm that this is needed. The idea is from this SO thread:
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
    return Time(secondsSinceEpoch: convertToSecondsSinceEpoch(year,
        month: month, day: day, hour: hour, minute: minute, second: second) -
        findLocalTimeDifference())
  }

  static public func utc(secondsSinceEpoch secs: Int, nanoseconds: Int = 0)
      -> Time {
    var t = Time(buffer: TimeBuffer.utc(secondsSinceEpoch: secs))
    t.nanoseconds = nanoseconds
    return t
  }

  static public var locale = Locale.one

}


public func <(lhs: Time, rhs: Time) -> Bool {
  return lhs.secondsSinceEpoch < rhs.secondsSinceEpoch ||
      (lhs.secondsSinceEpoch == rhs.secondsSinceEpoch &&
      lhs.nanoseconds < rhs.nanoseconds)
}

public func ==(lhs: Time, rhs: Time) -> Bool {
  return lhs.secondsSinceEpoch == rhs.secondsSinceEpoch &&
      lhs.nanoseconds == rhs.nanoseconds
}

public func !=(lhs: Time, rhs: Time) -> Bool {
  return lhs.secondsSinceEpoch != rhs.secondsSinceEpoch ||
      lhs.nanoseconds != rhs.nanoseconds
}

public func >(lhs: Time, rhs: Time) -> Bool {
  return lhs.secondsSinceEpoch > rhs.secondsSinceEpoch ||
      (lhs.secondsSinceEpoch == rhs.secondsSinceEpoch &&
      lhs.nanoseconds > rhs.nanoseconds)
}

public func <=(lhs: Time, rhs: Time) -> Bool {
  return lhs < rhs || lhs == rhs
}

public func >=(lhs: Time, rhs: Time) -> Bool {
  return lhs > rhs || lhs == rhs
}
