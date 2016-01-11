

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

  public static func read(filePath: String) throws -> String {
    var s: String?
    try File.open(filePath, mode: .R) { f in s = try! f.read() }
    return s!
  }

  public static func readLines(filePath: String) throws -> [String?] {
    var a: [String?]?
    try File.open(filePath, mode: .R) { f in a = try! f.readLines() }
    return a!
  }

  public static func readBytes(filePath: String) throws -> [UInt8] {
    let f = try File(path: filePath)
    defer { f.close() }
    return try f.readAllBytes()
  }

  public static func readCChar(filePath: String) throws -> [CChar] {
    let f = try File(path: filePath)
    defer { f.close() }
    return try f.readAllCChar()
  }

  public static func write(filePath: String, string: String) throws -> Int {
    var n: Int? = -1
    try File.open(filePath, mode: .W) { f in n = f.write(string) }
    return n!
  }

  public static func writeBytes(filePath: String,
      bytes: [UInt8]) throws -> Int {
    var n: Int? = -1
    try File.open(filePath, mode: .W) { f in
      n = f.writeBytes(bytes, maxBytes: bytes.count)
    }
    return n!
  }

  public static func writeCChar(filePath: String,
      bytes: [CChar]) throws -> Int {
    var n: Int? = -1
    try File.open(filePath, mode: .W) { f in
      n = f.writeCChar(bytes, maxBytes: bytes.count)
    }
    return n!
  }

  public static func popen(command: String, lineLength: Int32 = 80,
      fn: (string: String?) -> Void) throws {
    try PopenStream.readLines(command, lineLength: lineLength, fn: fn)
  }

  public static func popenBytes(command: String, maxBytes: Int = 80,
      fn: (bytes: [UInt8], length: Int) -> Void) throws {
    try PopenStream.readBytes(command, maxBytes: maxBytes, fn: fn)
  }

}


enum IOError: ErrorType {
  case readBytes
}
