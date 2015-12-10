
import CSua
import Glibc


public enum SysError: ErrorType {
    case InvalidOpenFileOperation(operation: String)
}

let _fflush = fflush;
let _getpid = getpid;

public class PosixSys {

  public static let DEFAULT_DIR_MODE = S_IRWXU | S_IRWXG | S_IRWXO

  public static let DEFAULT_FILE_MODE = S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP |
      S_IROTH

  public func openFile(filePath: String, operation: String = "r",
      mode: UInt32 = DEFAULT_FILE_MODE) throws -> Int32 {
    var flags: Int32 = 0
    if operation == "r" {
      flags = O_RDONLY
    } else if operation == "w" {
      flags = O_RDWR | O_CREAT | O_TRUNC
    } else if operation == "a" {
      flags = O_RDWR | O_CREAT | O_APPEND
    } else {
      throw SysError.InvalidOpenFileOperation(operation: operation)
    }
    flags |= O_CLOEXEC
    return retry({ csua_open(filePath, flags, mode) })
  }

  public func fflush(stream: UnsafeMutablePointer<FILE> = nil) -> Int32 {
    return _fflush(stream)
  }

  public func getpid() -> Int32 {
    return _getpid()
  }

  public func retry(fn: () -> Int32) -> Int32 {
    var value = fn()
    while value == -1 {
      if (errno != EINTR) { break }
      value = fn()
    }
    return value
  }

}

let Sys = PosixSys()
