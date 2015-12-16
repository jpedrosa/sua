

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

}


public enum PopenError: ErrorType {
  case FailedToStart()
}
