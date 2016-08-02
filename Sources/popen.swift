

public class Popen {

  public static func read(command: String) throws -> String? {
    let a = try readAllCChar(command: command)
    return String.fromCharCodes(charCodes: a)
  }

  public static func doPopen(command: String) throws -> FileStream {
    if let fp = Sys.popen(command: command) {
      return FileStream(fp: fp)
    }
    throw PopenError.Start
  }

  public static func doClose(fs: FileStream) {
    if let fp = fs.fp {
      let _ = Sys.pclose(fp: fp)
      fs.fp = nil
    }
  }

  public static func readAllCChar(command: String) throws -> [CChar] {
    let fs = try doPopen(command: command)
    defer { doClose(fs: fs) }
    return try fs.readAllCChar()
  }

  public static func readLines(command: String, fn: (string: String?)
      -> Void) throws {
    let fs = try doPopen(command: command)
    defer { doClose(fs: fs) }
    try fs.readLines(fn: fn)
  }

  public static func readByteLines(command: String, maxBytes: Int = 80,
      fn: (bytes: [UInt8], length: Int) -> Void) throws {
    let fs = try doPopen(command: command)
    defer { doClose(fs: fs) }
    try fs.readByteLines(maxBytes: maxBytes, fn: fn)
  }

}


public enum PopenError: ErrorProtocol {
  case Start
}
