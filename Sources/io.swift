
import Glibc


func nativeSleep(n: Int) {
  if (n >= 0) {
    sleep(UInt32(n))
  }
}

public class IO {

  public static func sleep(f: Double) {
    let sec = Int(f)
    let nsec = sec > 0 ? Int((f % Double(sec)) * 1e9) : Int(f * 1e9)
    var ts: timespec = timespec(tv_sec: sec, tv_nsec: nsec)
    var rem: timespec = timespec()
    nanosleep(&ts, &rem)
  }

  public static func sleep(n: Int) {
    nativeSleep(n)
  }

  public static func flush() {
    fflush(UnsafeMutablePointer<FILE>(bitPattern: 0))
  }

  public static func read(filePath: String) throws -> String {
    var s: String?
    try File.open(filePath, mode: .R) { f in s = try! f.read() }
    return s!
  }

  public static func readLines(filePath: String) throws -> [String] {
    var a: [String]?
    try File.open(filePath, mode: .R) { f in a = try! f.readLines() }
    return a!
  }

  public static func readBytes(filePath: String) throws -> [CChar] {
    var a: [CChar]?
    try File.open(filePath, mode: .R) { f in a = try! f.readBytes() }
    return a!
  }

  public static func write(filePath: String, string: String) throws -> Int {
    var n: Int? = -1
    try File.open(filePath, mode: .W) { f in n = f.write(string) }
    return n!
  }

  public static func writeBytes(filePath: String,
      bytes: [CChar]) throws -> Int {
    var n: Int? = -1
    try File.open(filePath, mode: .W) { f in n = f.writeBytes(bytes) }
    return n!
  }

  public static func writeUInt8(filePath: String,
      bytes: [UInt8]) throws -> Int {
    var n: Int? = -1
    try File.open(filePath, mode: .W) { f in n = f.writeUInt8(bytes) }
    return n!
  }

//  public static void writeBuffer(String filePath, ByteBuffer buffer) {
//    File.open(filePath, 'w', (f) => f.writeBuffer(buffer));
//  }

}
