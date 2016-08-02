
public class PosixStdin {

  public func doRead(address: UnsafeMutablePointer<Void>, maxBytes: Int) throws
      -> Int {
    if maxBytes < 0 {
      try _error(message: "Wrong read parameter value: negative maxBytes")
    }
    let n = Sys.read(fd: PosixSys.STDIN_FD, address: address, length: maxBytes)
    if n == -1 {
      try _error(message: "Failed to read from standard input.")
    }
    return n
  }

  public func readLines(fn: ((line: String?) -> Void)? = nil) throws
      -> [String?] {
    var a: [String?] = []
    let len = 1024
    var buffer = [UInt8](repeating: 0, count: len)
    var stream = ByteStream()
    var n = try doRead(address: &buffer, maxBytes: len)
    let hasFn = fn != nil
    while n > 0 {
      stream.merge(buffer: buffer, maxBytes: n)
      while stream.skipTo(c: 10) >= 0 { // \n
        stream.currentIndex += 1
        let s = stream.collectTokenString()
        stream.startIndex = stream.currentIndex
        if hasFn {
          fn!(line: s)
        } else {
          a.append(s)
        }
      }
      n = try doRead(address: &buffer, maxBytes: len)
    }
    let _ = stream.skipToEnd()
    if let s = stream.collectTokenString() {
      if hasFn {
        fn!(line: s)
      } else {
        a.append(s)
      }
    }
    return a
  }

  public func readByteLines(fn: ((line: [UInt8]) -> Void)? = nil) throws
      -> [UInt8] {
    var a: [UInt8] = []
    let len = 1024
    var buffer = [UInt8](repeating: 0, count: len)
    var stream = ByteStream()
    var n = try doRead(address: &buffer, maxBytes: len)
    let hasFn = fn != nil
    while n > 0 {
      stream.merge(buffer: buffer, maxBytes: n)
      while stream.skipTo(c: 10) >= 0 { // \n
        stream.currentIndex += 1
        let b = stream.collectToken()
        stream.startIndex = stream.currentIndex
        if hasFn {
          fn!(line: b)
        } else {
          a += b
        }
      }
      n = try doRead(address: &buffer, maxBytes: len)
    }
    let _ = stream.skipToEnd()
    let b = stream.collectToken()
    if b.count > 0 {
      if hasFn {
        fn!(line: b)
      } else {
        a += b
      }
    }
    return a
  }

  public func readBytes(maxBytes: Int = 1024) throws -> [UInt8]? {
    var a = [UInt8](repeating: 0, count: maxBytes)
    let n = try doRead(address: &a, maxBytes: maxBytes)
    if n <= 0 {
      return nil
    } else if n < maxBytes {
      a = [UInt8](a[0..<n])
    }
    return a
  }

  public var isTerminal: Bool {
    return Sys.isatty(fd: PosixSys.STDIN_FD)
  }

  func _error(message: String) throws {
    throw StdinError.StdinException(message: message)
  }

}


var _stdin: PosixStdin?

public var Stdin: PosixStdin {
  if _stdin == nil {
    _stdin = PosixStdin()
  }
  return _stdin!
}


public enum StdinError: ErrorProtocol {
  case StdinException(message: String)
}
