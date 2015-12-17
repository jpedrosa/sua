
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
let _stat = stat
let _lstat = lstat
let _readdir = readdir
let _opendir = opendir
let _closedir = closedir
let _fgets = fgets
let _popen = popen
let _pclose = pclose
let _fread = fread
let _getenv = getenv


public enum FileOperation: Int {
  case R
  case W
  case A
  case Read
  case Write
  case Append
}

public enum PopenOperation: String {
  case R
  case W
  case RE
  case WE
  case Read
  case Write
  case ReadWithCloexec
  case WriteWithCloexec
}

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

  public func openFile(filePath: String, operation: FileOperation = .R,
      mode: UInt32 = DEFAULT_FILE_MODE) -> Int32 {
    var flags: Int32 = 0
    switch operation {
      case .R, .Read: flags = O_RDONLY
      case .W, .Write: flags = O_RDWR | O_CREAT | O_TRUNC
      case .A, .Append: flags = O_RDWR | O_CREAT | O_APPEND
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
    var a = Array(string.utf8)
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

  public var pid: Int32 {
    return _getpid()
  }

  public func rename(oldPath: String, newPath: String) -> Int32 {
    return _rename(oldPath, newPath)
  }

  public func unlink(path: String) -> Int32 {
    return _unlink(path)
  }

  public var cwd: String? {
    var a = [CChar](count:256, repeatedValue: 0)
    let i = _getcwd(&a, 255)
    if i != nil {
      return String.fromCharCodes(a)
    }
    return nil
  }

  // Named with a do prefix to avoid conflict with functions and types of
  // name stat.
  public func doStat(path: String, buffer: UnsafeMutablePointer<stat>)
      -> Int32 {
    return _stat(path, buffer)
  }

  public func lstat(path: String, buffer: UnsafeMutablePointer<stat>) -> Int32 {
    return _lstat(path, buffer)
  }

  public func statBuffer() -> stat {
    return stat()
  }

  public func readdir(dirp: COpaquePointer) -> UnsafeMutablePointer<dirent> {
    return dirp != nil ? _readdir(dirp) : nil
  }

  public func opendir(dirPath: String) -> COpaquePointer {
    return _opendir(dirPath)
  }

  public func closedir(dirp: COpaquePointer) -> Int32 {
    return retry { _closedir(dirp) }
  }

  public func fgets(buffer: UnsafeMutablePointer<CChar>, length: Int32,
      fp: UnsafeMutablePointer<FILE>) -> UnsafeMutablePointer<CChar> {
    return _fgets(buffer, length, fp)
  }

  public func fread(buffer: UnsafeMutablePointer<Void>, size: Int,
      nmemb: Int, fp: UnsafeMutablePointer<FILE>) -> Int {
    return _fread(buffer, size, nmemb, fp)
  }

  public func popen(command: String, operation: PopenOperation = .R)
      -> UnsafeMutablePointer<FILE> {
    var op = "r"
    switch operation {
      case .R, .Read: op = "r"
      case .W, .Write: op = "w"
      case .RE, .ReadWithCloexec: op = "re"
      case .WE, .WriteWithCloexec: op = "we"
    }
    return _popen(command, op)
  }

  public func pclose(fp: UnsafeMutablePointer<FILE>) -> Int32 {
    return _pclose(fp)
  }

  public func getenv(key: String) -> String? {
    let vp = _getenv(key)
    return vp != nil ? String.fromCString(a) : nil
  }

  public var environment: [String: String] {
    var env = [String: String]()
    var i = 0
    while true {
      let nm = (environ + i).memory
      if nm == nil {
        break
      }
      let np = UnsafePointer<CChar>(nm)
      if let s = String.fromCString(np) {
        var b: [CChar] = s.utf8.map { CChar($0) }
        let lasti = b.count - 1
        for m in 0...lasti {
          if b[m] == 61 {
            if let k = String.fromCharCodes(b, start: 0, end: m - 1) {
              env[k] = String.fromCharCodes(b, start: m + 1, end: lasti) ?? ""
            }
            break
          }
        }
      }
      i++
    }
    return env
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

public let Sys = PosixSys()
