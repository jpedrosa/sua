

public class Ascii {

  public static func toLowerCase(c: UInt8) -> UInt8 {
    if c >= 65 && c <= 90 {
      return c + 32
    }
    return c
  }

  public static func toLowerCase(bytes: [UInt8]) -> [UInt8] {
    var a = bytes
    let len = a.count
    for i in 0..<len {
      let c = a[i]
      if c >= 65 && c <= 90 {
        a[i] = c + 32
      }
    }
    return a
  }

  public static func toLowerCase(bytes: [[UInt8]]) -> [[UInt8]] {
    var a = bytes
    let len = a.count
    for i in 0..<len {
      let b = a[i]
      let blen = b.count
      for bi in 0..<blen {
        let c = b[bi]
        if c >= 65 && c <= 90 {
          a[i][bi] = c + 32
        }
      }
    }
    return a
  }

  public static func toLowerCase(string: String) -> String? {
    return String.fromCharCodes(toLowerCase(string.bytes))
  }

}
