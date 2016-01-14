

public class Popen {

  public static func read(command: String) throws -> String? {
    let a = try readAllCChar(command)
    return String.fromCharCodes(a)
  }

  public static func doPopen(command: String) throws -> FileStream {
    let fp = Sys.popen(command)
    if fp == nil {
      throw PopenError.Start
    }
    return FileStream(fp: fp)
  }

  public static func readAllCChar(command: String) throws -> [CChar] {
    let fs = try doPopen(command)
    defer {
      if let afp = fs.fp {
        Sys.pclose(afp)
        fs.fp = nil
      }
    }
    return try fs.readAllCChar(command)
  }

  public static func readLines(command: String, fn: (string: String?)
      -> Void) throws {
    let fs = try doPopen(command)
    defer {
      if let afp = fs.fp {
        Sys.pclose(afp)
        fs.fp = nil
      }
    }
    try fs.readLines(command, fn: fn)
  }

  public static func readByteLines(command: String, maxBytes: Int = 80,
      fn: (bytes: [UInt8], length: Int) -> Void) throws {
    let fs = try doPopen(command)
    defer {
      if let afp = fs.fp {
        Sys.pclose(afp)
        fs.fp = nil
      }
    }
    try fs.readByteLines(command, maxBytes: maxBytes, fn: fn)
  }

}


public enum PopenError: ErrorType {
  case Start
}
