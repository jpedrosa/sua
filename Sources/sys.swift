
import CSua
import Glibc


enum SysError: ErrorType {
    case InvalidOpenFileOperation(operation: String)
}

class Sys {

  static let DEFAULT_DIR_MODE = S_IRWXU | S_IRWXG | S_IRWXO

  static let DEFAULT_FILE_MODE = S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP |
      S_IROTH

  static func openFile(filePath: String, operation: String = "r",
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
    flags |= O_CLOEXEC;
    let fd = retry({ csua_open(filePath, flags, mode) })
    //ForeignMemory cPath = new ForeignMemory.fromStringAsUTF8(filePath);
    //int fd = _retry(() => _open.icall$3(cPath, flags, mode));
    //cPath.free();
    return fd;
  }

  static func retry(fn: () -> Int32) -> Int32 {
    var value = fn()
    while value == -1 {
      if (errno != EINTR) { break }
      value = fn()
    }
    return value
  }

}
