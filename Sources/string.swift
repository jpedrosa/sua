

public extension String {

  /**
    It takes an array of char codes from which a new String will
    be generated.

    The start and end parameters can be omitted.

    The end parameter is inclusive. If the end parameter is negative, the end
    will be interpreted to be the value of the count of the array minus 1.

    **Note**: if the range includes a null value (0), since the String
    will be generated using a null-delimited C String function, the
    String may be truncated at the null value instead.

    E.g.:
        var a: [CChar] = [72, 101, 108, 108, 111]
        print(String.fromCharCodes(a)) // Prints Hello
        print(String.fromCharCodes(a, start: 1, end: 3)) // Prints ell
  */
  public static func fromCharCodes(charCodes: [CChar], start: Int = 0,
      end: Int = -1) -> String {
    let lasti = charCodes.count - 1
    let ei = end < 0 ? lasti : end
    if ei < start {
      return ""
    } else {
      var a: [CChar]
      if ei < lasti {
        a = [CChar](charCodes[start...ei + 1])
        a[a.count - 1] = 0
      } else {
        a = [CChar](charCodes[start...lasti])
        a.append(0)
      }
      return String.fromCString(&a)!
    }
  }

  public static func fromCharCodes(charCodes: [UInt8], start: Int = 0,
      end: Int = -1) -> String {
    let lasti = charCodes.count - 1
    let ei = end < 0 ? lasti : end
    if ei < start {
      return ""
    } else {
      var a: [UInt8]
      if ei < lasti {
        a = [UInt8](charCodes[start...ei + 1])
        a[a.count - 1] = 0
      } else {
        a = [UInt8](charCodes[start...lasti])
        a.append(0)
      }
      let ap = UnsafePointer<CChar>(a)
      return String.fromCString(ap)!
    }
  }

}
