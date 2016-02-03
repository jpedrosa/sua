

public struct RGBAColor {
  public var r: UInt8
  public var g: UInt8
  public var b: UInt8
  public var a: UInt8?
}


public struct Hexastyle {
  public var style = 0
  public var color: RGBAColor?
  public var backgroundColor: RGBAColor?

  public static let BOLD          = 2
  public static let UNDERLINE     = 4
  public static let ITALIC        = 8
  public static let STRIKEOUT     = 16

  func checkStyle(bit: Int) -> Bool {
    return (style & bit) > 0
  }

  public var isBold: Bool { return checkStyle(Hexastyle.BOLD) }

  public var isUnderline: Bool { return checkStyle(Hexastyle.UNDERLINE) }

  public var isItalic: Bool { return checkStyle(Hexastyle.ITALIC) }

  public var isStrikeOut: Bool { return checkStyle(Hexastyle.STRIKEOUT) }

  public static func matchHexa(c: UInt8) -> Bool {
    return (c >= 97 && c <= 102) || (c >= 65 && c <= 70) ||
        (c >= 48 && c <= 57)
  }

  // The sequence has to end in either = or , (comma).
  public static func parseHexaSequence(bytes: [UInt8], startIndex: Int,
      maxBytes: Int) throws -> (RGBAColor?, Int) {
    var i = startIndex
    let hti = HexaUtils.hexaToInt
    let c1 = bytes[i]
    if matchHexa(c1) && i + 3 < maxBytes {
      let c2 = bytes[i + 1]
      let c3 = bytes[i + 2]
      if matchHexa(c2) && matchHexa(c3) {
        i += 3
        let c4 = bytes[i]
        if c4 == 44 || c4 == 61 { // , =
          return (RGBAColor(r: hti(c1, c2: c1)!,
                           g: hti(c2, c2: c2)!,
                           b: hti(c3, c2: c3)!,
                           a: nil), i)
        } else if matchHexa(c4) {
          i += 1
          if i < maxBytes {
            let c5 = bytes[i]
            if c5 == 44 || c5 == 61 { // , =
              return (RGBAColor(r: hti(c1, c2: c1)!,
                               g: hti(c2, c2: c2)!,
                               b: hti(c3, c2: c3)!,
                               a: hti(c4, c2: c4)), i)
            } else if matchHexa(c5) && i + 2 < maxBytes {
              i += 1
              let c6 = bytes[i]
              if matchHexa(c6) {
                i += 1
                let c7 = bytes[i]
                if c7 == 44 || c7 == 61 { // , =
                  return (RGBAColor(r: hti(c1, c2: c2)!,
                                   g: hti(c3, c2: c4)!,
                                   b: hti(c5, c2: c6)!,
                                   a: nil), i)
                } else if matchHexa(c7) && i + 2 < maxBytes {
                  i += 1
                  let c8 = bytes[i]
                  if matchHexa(c8) {
                    i += 1
                    let c9 = bytes[i]
                    if c9 == 44 || c9 == 61 { // , =
                      return (RGBAColor(r: hti(c1, c2: c2)!,
                                       g: hti(c3, c2: c4)!,
                                       b: hti(c5, c2: c6)!,
                                       a: hti(c7, c2: c8)), i)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    return (nil, i)
  }

  // Starts from %^b#=. It starts past the percent character.
  public static func parseHexastyle(bytes: [UInt8], startIndex: Int,
      maxBytes: Int) throws -> (Hexastyle?, Int) {
    var i = startIndex
    var style = 0
    func parseColor() throws -> Hexastyle? {
      let (maybeColor, advi) = try parseHexaSequence(bytes, startIndex: i,
          maxBytes: maxBytes)
      i = advi
      if let color = maybeColor {
        let c = bytes[i]
        if c == 44 { // ,
          i += 1
          if i < maxBytes {
            let (maybeBgColor, advi) = try parseHexaSequence(bytes,
                startIndex: i, maxBytes: maxBytes)
            i = advi
            if let bgColor = maybeBgColor {
              if bytes[i] == 61 { // =
                return Hexastyle(style: style, color: color,
                    backgroundColor: bgColor)
              } else { // ,
                // Ignore.
              }
            } else {
              i -= 1 // Go back once, because the main while loop already
                     // increments it.
            }
          }
        } else if c == 61 { // =
          return Hexastyle(style: style, color: color, backgroundColor: nil)
        } else {
          throw HexastyleError.Unreachable
        }
      }
      return nil
    }
    if bytes[i] == 35 { // #
      i += 1
      if bytes[i] == 61 { // =
        return (Hexastyle(style:0, color: nil, backgroundColor: nil), i)
      } else {
        return (try parseColor(), i)
      }
    } else {
      STYLE: repeat {
        switch bytes[i] {
          case 98: // b
            if style & Hexastyle.BOLD > 0 {
              break STYLE
            }
            style |= Hexastyle.BOLD
          case 117: // u
            if style & Hexastyle.UNDERLINE > 0 {
              break STYLE
            }
            style |= Hexastyle.UNDERLINE
          case 115: // s
            if style & Hexastyle.STRIKEOUT > 0 {
              break STYLE
            }
            style |= Hexastyle.STRIKEOUT
          case 105: // i
            if style & Hexastyle.ITALIC > 0 {
              break STYLE
            }
            style |= Hexastyle.ITALIC
          case 35: // #
            i += 1
            if i < maxBytes {
              if bytes[i] == 61 { // =
                return (Hexastyle(style: style, color: nil,
                    backgroundColor: nil), i)
              } else {
                return (try parseColor(), i)
              }
            }
            break STYLE
          default: break STYLE
        }
        i += 1
      } while i < maxBytes
    }
    return (nil, i)
  }

  public static func parseText(string: String) throws
      -> [(String, Hexastyle?)] {
    let a = string.bytes
    return try parseBytes(a, startIndex: 0, maxBytes: a.count)
  }

  public static func parseBytes(bytes: [UInt8], startIndex: Int,
      maxBytes: Int) throws -> [(String, Hexastyle?)] {
    var i = startIndex
    var tokenIndex = i
    let len = maxBytes
    var list = [(String, Hexastyle?)]()
    let vlen = len - 2
    var hexac: Hexastyle?
    func collect(ei: Int) throws {
      if let z = String.fromCharCodes(bytes, start: tokenIndex, end: ei) {
        list.append((z, hexac))
      } else {
        throw HexastyleError.Unicode
      }
    }
    while i < vlen {
      if bytes[i] == 37 { // %
        let (hc, advi) = try parseHexastyle(bytes, startIndex: i + 1,
            maxBytes: len)
        if let _ = hc {
          if i - 1 >= tokenIndex {
            try collect(i - 1)
          }
          tokenIndex = advi + 1
        }
        hexac = hc
        i = advi
      }
      i += 1
    }
    if tokenIndex < len {
      try collect(len)
    }
    return list
  }

}


public enum HexastyleError: ErrorType {
  case Parse
  case Unicode
  case Unreachable
}
