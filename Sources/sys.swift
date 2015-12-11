
import CSua
import Glibc


public enum SysError: ErrorType {
  case InvalidOpenFileOperation(operation: String)
}

let _fflush = fflush
let _getpid = getpid
let _close = close
let _mkdir = mkdir
let _read = read
let _write = write
let _lseek = lseek
let _rename = rename
let _unlink = unlink
let _getcwd = getcwd

public class PosixSys {

  public static let DEFAULT_DIR_MODE = S_IRWXU | S_IRWXG | S_IRWXO

  public static let DEFAULT_FILE_MODE = S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP |
      S_IROTH

  public static let SEEK_SET: Int32 = 0
  public static let SEEK_CUR: Int32 = 1
  public static let SEEK_END: Int32 = 2

  public func open(path: String, flags: Int32, mode: UInt32) -> Int32 {
    return retry { csua_open(path, flags, mode) }
  }

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
    return open(filePath, flags: flags, mode: mode)
  }

  public func doOpenDir(dirPath: String) -> Int32 {
    return open(dirPath, flags: O_RDONLY | O_DIRECTORY, mode: 0)
  }

  public func mkdir(dirPath: String, mode: UInt32 = DEFAULT_DIR_MODE) -> Int32 {
    return retry { _mkdir(dirPath, mode) }
  }

  public func read(fd: Int32, address: UnsafeMutablePointer<Void>,
      length: Int) -> Int {
    return retry { _read(fd, address, length) }
  }

  public func write(fd: Int32, address: UnsafePointer<Void>,
      length: Int) -> Int {
    return retry { _write(fd, address, length) }
  }

  public func writeString(fd: Int32, string: String) -> Int {
    var a: [CChar] = string.utf8.map { CChar($0) }
    return write(fd, address: &a, length: a.count)
  }

  public func close(fd: Int32) -> Int32 {
    return retry { _close(fd) }
  }

  public func fflush(stream: UnsafeMutablePointer<FILE> = nil) -> Int32 {
    return _fflush(stream)
  }

  public func lseek(fd: Int32, offset: Int, whence: Int32) -> Int {
    return retry { _lseek(fd, offset, whence) }
  }

  public func getpid() -> Int32 {
    return _getpid()
  }

  public func rename(oldPath: String, newPath: String) -> Int32 {
    return _rename(oldPath, newPath)
  }

  public func unlink(path: String) -> Int32 {
    return _unlink(path)
  }

  public func getcwd() -> String? {
    var a = [CChar](count:256, repeatedValue: 0)
    let i = _getcwd(&a, 255)
    if i != nil {
      return String.fromCharCodes(a)
    }
    return nil
  }

  public func retry(fn: () -> Int32) -> Int32 {
    var value = fn()
    while value == -1 {
      if errno != EINTR { break }
      value = fn()
    }
    return value
  }

  public func retry(fn: () -> Int) -> Int {
    var value = fn()
    while value == -1 {
      if errno != EINTR { break }
      value = fn()
    }
    return value
  }

}

let Sys = PosixSys()
