
public class PosixStdin {

  public func doRead(address: UnsafeMutablePointer<Void>, maxBytes: Int) throws
      -> Int {
    if maxBytes < 0 {
      try _error("Wrong read parameter value: negative maxBytes")
    }
    let n = Sys.read(PosixSys.STDIN_FD, address: address, length: maxBytes)
    if n == -1 {
      try _error("Failed to read from standard input.")
    }
    return n
  }

  public func readLines(fn: ((line: String?) -> Void)? = nil) throws
      -> [String?] {
    var a: [String?] = []
    let len = 1024
    var buffer = [UInt8](count: len, repeatedValue: 0)
    var stream = ByteStream()
    var n = try doRead(&buffer, maxBytes: len)
    let hasFn = fn != nil
    while n > 0 {
      stream.merge(buffer, maxBytes: n)
      while stream.skipTo(10) >= 0 { // \n
        stream.currentIndex += 1
        let s = stream.collectTokenString()
        stream.startIndex = stream.currentIndex
        if hasFn {
          fn!(line: s)
        } else {
          a.append(s)
        }
      }
      n = try doRead(&buffer, maxBytes: len)
    }
    stream.skipToEnd()
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
    var buffer = [UInt8](count: len, repeatedValue: 0)
    var stream = ByteStream()
    var n = try doRead(&buffer, maxBytes: len)
    let hasFn = fn != nil
    while n > 0 {
      stream.merge(buffer, maxBytes: n)
      while stream.skipTo(10) >= 0 { // \n
        stream.currentIndex += 1
        let b = stream.collectToken()
        stream.startIndex = stream.currentIndex
        if hasFn {
          fn!(line: b)
        } else {
          a += b
        }
      }
      n = try doRead(&buffer, maxBytes: len)
    }
    stream.skipToEnd()
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
    var a = [UInt8](count: maxBytes, repeatedValue: 0)
    let n = try doRead(&a, maxBytes: maxBytes)
    if n <= 0 {
      return nil
    } else if n < maxBytes {
      a = [UInt8](a[0..<n])
    }
    return a
  }

  public var isTerminal: Bool {
    return Sys.isatty(PosixSys.STDIN_FD)
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


public enum StdinError: ErrorType {
  case StdinException(message: String)
}
