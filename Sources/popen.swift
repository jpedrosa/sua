

public class Popen {

  public static func read(command: String) throws -> String? {
    let a = try readAllCChar(command)
    return String.fromCharCodes(a)
  }

  public static func readAllCChar(command: String) throws -> [CChar] {
    let fp = Sys.popen(command)
    defer { Sys.pclose(fp) }
    var a = [CChar](count: 1024, repeatedValue: 0)
    if fp == nil {
      throw PopenError.Start
    } else {
      var buffer = [CChar](count: 1024, repeatedValue: 0)
      var alen = 1024
      var j = 0
      while Sys.fgets(&buffer, length: 1024, fp: fp) != nil {
        for i in 0..<1024 {
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
    }
    return a
  }

  public static func readLines(command: String, lineLength: Int32 = 80,
      fn: (string: String?) -> Void) throws {
    var fp = Sys.popen(command)
    if fp == nil {
      throw PopenError.Start
    } else {
      defer {
        Sys.pclose(fp)
      }
      var buffer = [CChar](count: Int(lineLength + 1), repeatedValue: 0)
      while Sys.fgets(&buffer, length: lineLength, fp: fp) != nil {
        fn(string: String.fromCharCodes(buffer))
      }
    }
  }

  public static func readByteLines(command: String, maxBytes: Int = 80,
      fn: (bytes: [UInt8], length: Int) -> Void) throws {
    var fp = Sys.popen(command)
    if fp == nil {
      throw PopenError.Start
    } else {
      defer {
        Sys.pclose(fp)
      }
      var buffer = [UInt8](count: Int(maxBytes), repeatedValue: 0)
      var n: Int
      repeat {
        n = Sys.fread(&buffer, size: 1, nmemb: maxBytes, fp: fp)
        if n > 0 {
          fn(bytes: buffer, length: n)
        }
      } while n > 0
    }
  }

}


public enum PopenError: ErrorType {
  case Start
}
