

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
        print(String.fromCharCodes(a) ?? "") // Prints Hello
        print(String.fromCharCodes(a, start: 1, end: 3) ?? "") // Prints ell
  */
  public static func fromCharCodes(charCodes: [CChar], start: Int = 0,
      end: Int = -1) -> String? {
    let lasti = charCodes.count - 1
    let ei = end < 0 ? lasti : end
    if ei < start {
      return nil
    } else {
      var a: [CChar]
      if ei < lasti {
        a = [CChar](charCodes[start...ei + 1])
        a[a.count - 1] = 0
      } else {
        a = [CChar](charCodes[start...lasti])
        if a[a.count - 1] != 0 {
          a.append(0)
        }
      }
      return String.fromCString(&a)
    }
  }

  public static func fromCharCodes(charCodes: [UInt8], start: Int = 0,
      end: Int = -1) -> String? {
    let lasti = charCodes.count - 1
    let ei = end < 0 ? lasti : end
    if ei < start {
      return nil
    } else {
      var a: [UInt8]
      if ei < lasti {
        a = [UInt8](charCodes[start...ei + 1])
        a[a.count - 1] = 0
      } else {
        a = [UInt8](charCodes[start...lasti])
        if a[a.count - 1] != 0 {
          a.append(0)
        }
      }
      let ap = UnsafePointer<CChar>(a)
      return String.fromCString(ap)
    }
  }


  /**
    Splits a string once or into 2 halves by returning a tuple with the left
    and right values.

    If the string pattern is not found at all, the left value will always be
    nil.

    E.g.:
        print("abcdef".splitOnce("cd")) // Prints (Optional("ab"), Optional("ef"))
        print("abcdef".splitOnce("xy")) // Prints (nil, nil)
        print("abcdef".splitOnce("ab")) // Prints (Optional(""), Optional("cdef"))
        print("abcdef".splitOnce("ef")) // (Optional("abcd"), nil)
  */
  public func splitOnce(string: String) -> (left: String?, right: String?) {
    var left: String?
    var right: String?
    if !string.isEmpty {
      let sfc = string.utf16.codeUnitAt(0)
      let jlen = string.utf16.count
      let len = utf16.count
      let validLen = len - jlen + 1
      for i in 0..<validLen {
        if utf16.codeUnitAt(i) == sfc {
          var ok = true
          var j = 1
          while j < jlen {
            if utf16.codeUnitAt(i + j) != string.utf16.codeUnitAt(j) {
              ok = false
              break
            }
            j += 1
          }
          if ok {
            left = utf16.substring(0, endIndex: i)
            if i + j < len {
              right = utf16.substring(i + j, endIndex: len)
            }
            break
          }
        }
      }
    }
    return (left, right)
  }

  // Just a very handy method for returning the String bytes.
  public var bytes: [UInt8] { return [UInt8](utf8) }

}


public extension String.UTF16View {

  // Handy method for obtaining a string out of UTF16 indices.
  public func substring(startIndex: Int, endIndex: Int)
      -> String? {
    return String(self[self.startIndex.advancedBy(
        startIndex)..<self.startIndex.advancedBy(endIndex)])
  }

  // Handy method for obtaining a UTF16 code unit to compare with.
  public func codeUnitAt(index: Int) -> UInt16 {
    return self[startIndex.advancedBy(index)]
  }

  public func endsWith(string: String) -> Bool {
    let a = string.utf16
    let alen = a.count
    let len = self.count
    if len >= alen && alen > 0 {
      let j = len - alen
      for i in 0..<alen {
        if a.codeUnitAt(i) != self.codeUnitAt(j + i) {
          return false
        }
      }
      return true
    }
    return false
  }

}


public extension String.CharacterView {

  // Handy method for obtaining a string out of character indices.
  public func substring(startIndex: Int, endIndex: Int)
      -> String {
    return String(self[self.startIndex.advancedBy(
        startIndex)..<self.startIndex.advancedBy(endIndex)])
  }

}
