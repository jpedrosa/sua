

public class Locale {

  public let months = [
      "January", "February", "March", "April", "May", "June", "July",
      "August", "Septemper", "October", "November", "December"]

  public let abbreviatedMonths = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct",
      "Nov", "Dec"]

  public let weekdays = [
      "Monday", "Thuesday", "Wednesday", "Thursday", "Friday", "Saturday",
      "Sunday"]

  public let abbreviatedWeekdays = ["Mon", "Thu", "Wed", "Thu", "Fri", "Sat",
      "Sun"]

  // Formats time like the strftime function in C.
  // We're still missing some of the features though.
  // E.g.
  //    p(Time().strftime("%Y-%m-%d %H:%M:%S")) //> "2015-12-29 04:06:12"
  public func strftime(time: Time, mask: String) -> String {
    var sb = ""
    var tokenIndex = -1
    var i = 0
    func process(z: String, padding: Int = 0) {
      if tokenIndex >= 0 {
        sb += mask.utf16.substring(tokenIndex, endIndex: i - 1) ?? ""
        tokenIndex = -1
      }
      var j = z.utf16.count - padding
      while j < 0 {
        sb += "0"
        j += 1
      }
      sb += z
    }
    let len = mask.utf16.count
    let lasti = len - 1
    while i < len {
      if mask.utf16.codeUnitAt(i) == 37 && i < lasti { // %
        i += 1
        switch mask.utf16.codeUnitAt(i) {
        case 37: // %
          sb += "%"
        case 45: // -
          if i < lasti {
            if mask.utf16.codeUnitAt(i + 1) == 100 { // d
              process("\(time.day)")
              i += 1
            } else {
              i -= 1
            }
          } else {
            i -= 1
          }
        case 65: // A
          process(weekdays[time.weekday - 1])
        case 66: // B
          process(months[time.month - 1])
        case 72: // H
          process("\(time.hour)", padding: 2)
        case 76: // L
          process("\(time.nanoseconds / 1000000)", padding: 3)
        case 77: // M
          process("\(time.minute)", padding: 2)
        case 80: // P
          process(time.hour >= 12 ? "PM" : "AM")
        case 83: // S
          process("\(time.second)", padding: 2)
        case 89: // Y
          process("\(time.year)", padding: 4)
        case 97: // a
          process(abbreviatedWeekdays[time.weekday - 1])
        case 98: // b
          process(abbreviatedMonths[time.month - 1])
        case 100: // d
          process("\(time.day)", padding: 2)
        case 109: // m
          process("\(time.month)", padding: 2)
        case 112: // p
          process(time.hour >= 12 ? "pm" : "am")
        default:
          i -= 1
        }
      } else {
        if tokenIndex < 0 {
          tokenIndex = i
        }
      }
      i += 1
    }
    if tokenIndex >= 0 {
      sb += mask.utf16.substring(tokenIndex, endIndex: i) ?? ""
    }
    return sb
  }

  public func formatDouble(f: Double, precision: Int = 2) -> String {
    var p = 1
    for _ in 0..<precision {
      p *= 10
    }
    let neutral = Math.abs(Math.round((f * Double(p))))
    var s = ""
    let a = "\(neutral)".characters
    let len = a.count
    var dot = len - precision
    if f < 0 {
      s += "-"
    }
    if dot <= 0 {
      dot = 1
    }
    let pad = precision - len
    var i = 0
    while i <= pad {
      s += i == dot ? ".0" : "0"
      i += 1
    }
    for c in a {
      if i == dot {
        s += "."
      }
      s.append(c)
      i += 1
    }
    return s
  }

  // Default, constant locale that can be used when the format requires
  // American, English or standard system compatibility.
  public static let one = Locale()

}
