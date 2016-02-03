

public class HexaUtils {

  public static func hexaToInt(c1: UInt8, c2: UInt8) -> UInt8? {
    var n = -1
    let v1 = Int(c1)
    let v2 = Int(c2)
    if v1 >= 65 && v1 <= 70 { // A-F
      n = 16 * (v1 - 55)
    } else if v1 >= 97 && v1 <= 102 { // a-f
      n = 16 * (v1 - 87)
    } else if v1 >= 48 && v1 <= 57 { // 0-9
      n = 16 * (v1 - 48)
    }
    if n >= 0 {
      if v2 >= 65 && v2 <= 70 { // A-F
        return UInt8(n + (v2 - 55))
      } else if v2 >= 97 && v2 <= 102 { // a-f
        return UInt8(n + (v2 - 87))
      } else if v2 >= 48 && v2 <= 57 { // 0-9
        return UInt8(n + (v2 - 48))
      }
    }
    return nil
  }

  public static func formUrlDecode(bytes: [UInt8], maxBytes: Int) -> [UInt8]? {
    var a = [UInt8]()
    a.reserveCapacity(maxBytes)
    var i = 0
    while i < maxBytes {
      let c = bytes[i]
      if c == 43 {
        a.append(32)
        i += 1
      } else if c == 37 {
        if i + 2 < maxBytes {
          if let n = hexaToInt(bytes[i + 1], c2: bytes[i + 2]) {
            a.append(n)
            i += 3
          } else {
            return nil
          }
        } else {
          return nil
        }
      } else {
        a.append(c)
        i += 1
      }
    }
    return a
  }

  // Make sure it is a value between 0 and 15 before calling it.
  public static func toLiteral(f: UInt8) -> String {
    switch f {
      case 10:
        return "A"
      case 11:
        return "B"
      case 12:
        return "C"
      case 13:
        return "D"
      case 14:
        return "E"
      case 15:
        return "F"
      default:
        return "\(f)"
    }
  }

  public static func hexaToString(c: UInt8, pad: Bool = false) -> String {
    if c >= 16 {
      let n = c % 16
      let rest = c - (n * 16)
      return "\(toLiteral(n))\(toLiteral(rest))"
    } else if pad {
      return "0\(toLiteral(c))"
    }
    return toLiteral(c)
  }

}
