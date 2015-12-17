

public class PopenStream {

  public static func readLines(command: String, lineLength: Int32 = 80,
      fn: (string: String?) -> Void) throws {
    var fp = Sys.popen(command)
    if fp == nil {
      PopenError.FailedToStart()
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

  public static func readBytes(command: String, maxBytes: Int = 80,
      fn: (bytes: [UInt8], length: Int) -> Void) throws {
    var fp = Sys.popen(command)
    if fp == nil {
      PopenError.FailedToStart()
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
  case FailedToStart()
}
