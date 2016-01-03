

public class ByteOrder {

  // Create our own version of the C function htons().
  static public func htons(value: UInt16) -> UInt16 {
    var v = value
    return withUnsafePointer(&v) { (ptr) -> UInt16 in
      let ap = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(ptr),
          count: sizeofValue(v))
      var n: UInt16 = 0
      withUnsafePointer(&n) { np in
        let np = UnsafeMutableBufferPointer<UInt8>(
              start: UnsafeMutablePointer<UInt8>(np), count: sizeofValue(n))
        np[0] = ap[1]
        np[1] = ap[0]
      }
      return n
    }
  }

  // Create our own version of the C function htons().
  static public func htonl(value: UInt32) -> UInt32 {
    var v = value
    p("yyyyyyy", v)
    return withUnsafePointer(&v) { (ptr) -> UInt32 in
      let ap = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(ptr),
          count: sizeofValue(v))
      var n: UInt32 = 0
      withUnsafePointer(&n) { np in
        let np = UnsafeMutableBufferPointer<UInt8>(
              start: UnsafeMutablePointer<UInt8>(np), count: sizeofValue(n))
        np[0] = ap[3]
        np[1] = ap[2]
        np[2] = ap[1]
        np[3] = ap[0]
      }
      p("nnnnnnn", n)
      return n
    }
  }

}
