
import CSua
import Glibc


public enum FileOperation: Int {
  case R // Read
  case W // Write
  case A // Append
}

public enum PopenOperation: String {
  case R = "r" // Read
  case W = "w" // Write
  case RE = "re" // ReadWithCloexec
  case WE = "we" // WriteWithCloexec
}


public class Signal {

  // The callback closure must be created directly from a function on the
  // outer scope so that it does not capture context. As required by Swift for
  // callbacks to C functions.
  public static var trap = Glibc.signal

  public static let INT = SIGINT
  public static let TERM = SIGTERM
  public static let ABRT = SIGABRT
  public static let KILL = SIGKILL
  public static let HUP = SIGHUP
  public static let ALRM = SIGALRM
  public static let CHLD = SIGCHLD

}


// This alias allows other files like the FileBrowser to declare this type
// without having to import Glibc as well.
public typealias CDirentPointer = UnsafeMutablePointer<dirent>

public typealias CStat = stat

public typealias CTimespec = timespec

public typealias CTime = tm

public typealias CFilePointer = UnsafeMutablePointer<FILE>


func statStruct() -> CStat {
  return stat()
}


public struct PosixSys {

  public static let DEFAULT_DIR_MODE = S_IRWXU | S_IRWXG | S_IRWXO

  public static let DEFAULT_FILE_MODE = S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP |
      S_IROTH

  public static let USER_RW_FILE_MODE: UInt32 = S_IRUSR | S_IWUSR

  public static let SEEK_SET: Int32 = 0
  public static let SEEK_CUR: Int32 = 1
  public static let SEEK_END: Int32 = 2

  public static let STDIN_FD: Int32 = 0
  public static let STDOUT_FD: Int32 = 1
  public static let STDERR_FD: Int32 = 2

  public func open(path: String, flags: Int32, mode: UInt32) -> Int32 {
    return retry { Glibc.open(path, flags, mode) }
  }

  public func openFile(filePath: String, operation: FileOperation = .R,
      mode: UInt32 = DEFAULT_FILE_MODE) -> Int32 {
    var flags: Int32 = 0
    switch operation {
      case .R: flags = O_RDONLY
      case .W: flags = O_RDWR | O_CREAT | O_TRUNC
      case .A: flags = O_RDWR | O_CREAT | O_APPEND
    }
    flags |= O_CLOEXEC
    return open(filePath, flags: flags, mode: mode)
  }

  public func doOpenDir(dirPath: String) -> Int32 {
    return open(dirPath, flags: O_RDONLY | O_DIRECTORY, mode: 0)
  }

  public func mkdir(dirPath: String, mode: UInt32 = DEFAULT_DIR_MODE) -> Int32 {
    return retry { Glibc.mkdir(dirPath, mode) }
  }

  public func read(fd: Int32, address: UnsafeMutablePointer<Void>,
      length: Int) -> Int {
    return retry { Glibc.read(fd, address, length) }
  }

  public func write(fd: Int32, address: UnsafePointer<Void>,
      length: Int) -> Int {
    return retry { Glibc.write(fd, address, length) }
  }

  public func writeString(fd: Int32, string: String) -> Int {
    var a = Array(string.utf8)
    return write(fd, address: &a, length: a.count)
  }

  public func writeBytes(fd: Int32, bytes: [UInt8], maxBytes: Int)
      -> Int {
    var a = bytes
    return write(fd, address: &a, length: maxBytes)
  }

  public func close(fd: Int32) -> Int32 {
    return retry { Glibc.close(fd) }
  }

  public func fflush(stream: CFilePointer = nil) -> Int32 {
    return Glibc.fflush(stream)
  }

  public func lseek(fd: Int32, offset: Int, whence: Int32) -> Int {
    return retry { Glibc.lseek(fd, offset, whence) }
  }

  public var pid: Int32 {
    return Glibc.getpid()
  }

  public func rename(oldPath: String, newPath: String) -> Int32 {
    return Glibc.rename(oldPath, newPath)
  }

  public func unlink(path: String) -> Int32 {
    return Glibc.unlink(path)
  }

  public var cwd: String? {
    var a = [CChar](count:256, repeatedValue: 0)
    let i = Glibc.getcwd(&a, 255)
    if i != nil {
      return String.fromCharCodes(a)
    }
    return nil
  }

  public func stat(path: String, buffer: UnsafeMutablePointer<CStat>)
      -> Int32 {
    return Glibc.stat(path, buffer)
  }

  public func lstat(path: String, buffer: UnsafeMutablePointer<CStat>)
      -> Int32 {
    return Glibc.lstat(path, buffer)
  }

  public func statBuffer() -> CStat {
    return statStruct()
  }

  public func readdir(dirp: COpaquePointer) -> CDirentPointer {
    return dirp != nil ? Glibc.readdir(dirp) : nil
  }

  public func opendir(path: String) -> COpaquePointer {
    return Glibc.opendir(path)
  }

  public func opendir(pathBytes: [UInt8]) -> COpaquePointer {
    return Glibc.opendir(UnsafePointer<CChar>(pathBytes))
  }

  public func closedir(dirp: COpaquePointer) -> Int32 {
    return retry { Glibc.closedir(dirp) }
  }

  public func fgets(buffer: UnsafeMutablePointer<CChar>, length: Int32,
      fp: CFilePointer) -> UnsafeMutablePointer<CChar> {
    return Glibc.fgets(buffer, length, fp)
  }

  public func fread(buffer: UnsafeMutablePointer<Void>, size: Int,
      nmemb: Int, fp: CFilePointer) -> Int {
    return Glibc.fread(buffer, size, nmemb, fp)
  }

  public func fclose(fp: CFilePointer) -> Int32 {
    return Glibc.fclose(fp)
  }

  public func popen(command: String, operation: PopenOperation = .R)
      -> CFilePointer {
    return Glibc.popen(command, operation.rawValue)
  }

  public func pclose(fp: CFilePointer) -> Int32 {
    return Glibc.pclose(fp)
  }

  public func isatty(fd: Int32) -> Bool {
    return Glibc.isatty(fd) == 1
  }

  public func strlen(sp: UnsafePointer<CChar>) -> UInt {
    return Glibc.strlen(sp)
  }

  public func sleep(n: UInt32) -> UInt32 {
    return Glibc.sleep(n)
  }

  public func nanosleep(seconds: Int, nanoseconds: Int = 0) -> Int32 {
    var ts: CTimespec = Glibc.timespec(tv_sec: seconds, tv_nsec: nanoseconds)
    return retry { Glibc.nanosleep(&ts, nil) }
  }

  public func time() -> Int {
    return Glibc.time(nil)
  }

  public func timeBuffer() -> CTime {
    return Glibc.tm()
  }

  public func localtime_r(secondsSinceEpoch: Int,
      buffer: UnsafeMutablePointer<CTime>) {
    var n = secondsSinceEpoch
    Glibc.localtime_r(&n, buffer)
  }

  public func gmtime_r(secondsSinceEpoch: Int,
      buffer: UnsafeMutablePointer<CTime>) {
    var n = secondsSinceEpoch
    Glibc.gmtime_r(&n, buffer)
  }

  public func abs(n: Int32) -> Int32 {
    return Glibc.abs(n)
  }

  public func abs(n: Int) -> Int {
    return Glibc.labs(n)
  }

  public func round(f: Double) -> Int {
    return Int(Glibc.round(f))
  }

  public func getenv(name: String) -> String? {
    let vp = Glibc.getenv(name)
    return vp != nil ? String.fromCString(vp) : nil
  }

  public func setenv(name: String, value: String) -> Int32 {
    return Glibc.setenv(name, value, 1)
  }

  public func unsetenv(name: String) -> Int32 {
    return Glibc.unsetenv(name)
  }

  // The environ variable is made available by the CSua sister project
  // dependency.
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
        let (name, value) = s.splitOnce("=")
        env[name!] = value ?? ""
      }
      i += 1
    }
    return env
  }

  public func getpwnam(name: String) -> UnsafeMutablePointer<passwd> {
    return Glibc.getpwnam(name)
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
