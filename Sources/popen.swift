

public class Popen {

  public static func read(command: String) throws -> String? {
    let a = try readAllCChar(command)
    return String.fromCharCodes(a)
  }

  public static func doPopen(command: String) throws -> CFilePointer {
    let fp = Sys.popen(command)
    if fp == nil {
      throw PopenError.Start
    }
    return fp
  }

  public static let SIZE = 80 // Starting buffer size.

  public static func readAllCChar(command: String) throws -> [CChar] {
    let fp = try doPopen(command)
    defer { Sys.pclose(fp) }
    var a = [CChar](count: SIZE, repeatedValue: 0)
    var buffer = [CChar](count: SIZE, repeatedValue: 0)
    var alen = SIZE
    var j = 0
    while Sys.fgets(&buffer, length: Int32(SIZE), fp: fp) != nil {
      for i in 0..<SIZE {
        let c = buffer[i]
        if c == 0 {
          break
        }
        if j >= alen {
          var b = [CChar](count: alen * 8, repeatedValue: 0)
          for m in 0..<alen {
            b[m] = a[m]
          }
          a = b
          alen = b.count
        }
        a[j] = c
        j += 1
      }
    }
    return a
  }

  public static func readLines(command: String, fn: (string: String?)
      -> Void) throws {
    var fp = try doPopen(command)
    defer { Sys.pclose(fp) }
    var a = [CChar](count: SIZE, repeatedValue: 0)
    var buffer = [CChar](count: SIZE, repeatedValue: 0)
    var alen = SIZE
    var j = 0
    while Sys.fgets(&buffer, length: Int32(SIZE), fp: fp) != nil {
      var i = 0
      while i < SIZE {
        let c = buffer[i]
        if c == 0 {
          break
        }
        if j >= alen {
          var b = [CChar](count: alen * 8, repeatedValue: 0)
          for m in 0..<alen {
            b[m] = a[m]
          }
          a = b
          alen = b.count
        }
        a[j] = c
        if c == 10 {
          fn(string: String.fromCharCodes(a, start: 0, end: j))
          j = 0
        } else {
          j += 1
        }
        i += 1
      }
    }
    if j > 0 {
      fn(string: String.fromCharCodes(a, start: 0, end: j - 1))
    }
  }

  public static func readByteLines(command: String, maxBytes: Int = 80,
      fn: (bytes: [UInt8], length: Int) -> Void) throws {
    var fp = try doPopen(command)
    defer { Sys.pclose(fp) }
    var buffer = [UInt8](count: Int(maxBytes), repeatedValue: 0)
    while true {
      let n = Sys.fread(&buffer, size: 1, nmemb: maxBytes, fp: fp)
      if n > 0 {
        fn(bytes: buffer, length: n)
      } else {
        break
      }
    }
  }

}


public enum PopenError: ErrorType {
  case Start
}
