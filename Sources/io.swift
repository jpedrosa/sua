

public class IO {

  public static func sleep(f: Double) {
    let sec = Int(f)
    let nsec = sec > 0 ? Int((f % Double(sec)) * 1e9) : Int(f * 1e9)
    Sys.nanosleep(sec, nanoseconds: nsec)
  }

  public static func sleep(n: Int) {
    if n >= 0 {
      Sys.sleep(UInt32(n))
    }
  }

  public static func flush() {
    Sys.fflush()
  }

  public static func read(filePath: String, maxBytes: Int = -1) throws
      -> String? {
    let f = try File(path: filePath)
    defer { f.close() }
    return try f.read(maxBytes)
  }

  public static func readLines(filePath: String) throws -> [String?] {
    let f = try File(path: filePath)
    defer { f.close() }
    return try f.readLines()
  }

  public static func readAllBytes(filePath: String) throws -> [UInt8] {
    let f = try File(path: filePath)
    defer { f.close() }
    return try f.readAllBytes()
  }

  public static func readAllCChar(filePath: String) throws -> [CChar] {
    let f = try File(path: filePath)
    defer { f.close() }
    return try f.readAllCChar()
  }

  public static func write(filePath: String, string: String) throws -> Int {
    let f = try File(path: filePath, mode: .W)
    defer { f.close() }
    return f.write(string)
  }

  public static func writeBytes(filePath: String, bytes: [UInt8],
      maxBytes: Int) throws -> Int {
    let f = try File(path: filePath, mode: .W)
    defer { f.close() }
    return f.writeBytes(bytes, maxBytes: maxBytes)
  }

  public static func writeCChar(filePath: String, bytes: [CChar],
      maxBytes: Int) throws -> Int {
    let f = try File(path: filePath, mode: .W)
    defer { f.close() }
    return f.writeCChar(bytes, maxBytes: maxBytes)
  }

  public static var env: Environment {
    return Environment()
  }

}


public struct Environment: SequenceType {

  public subscript(name: String) -> String? {
    get { return Sys.getenv(name) }
    set {
      if let v = newValue {
        Sys.setenv(name, value: v)
      } else {
        Sys.unsetenv(name)
      }
    }
  }

  public func generate() -> DictionaryGenerator<String, String> {
    return Sys.environment.generate()
  }

}
