
public class PosixStdin {

  public func doRead(address: UnsafeMutablePointer<Void>, maxBytes: Int) throws
      -> Int {
    if maxBytes < 0 {
      try _error("Wrong read parameter value: negative maxBytes")
    }
    let n = Sys.read(0, address: address, length: maxBytes)
    if n == -1 {
      try _error("Failed to read from standard input.")
    }
    return n
  }

  public func read() throws -> String? {
    return nil
  }

  public func readBytes(maxBytes: Int = 1024) throws -> [UInt8]? {
    var a = [UInt8](count: maxBytes, repeatedValue: 0)
    let n = try doRead(&a, maxBytes: maxBytes)
    if n < maxBytes {
      a = a[0..<n].map { UInt8($0) }
    }
    return a
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
