

public class File: CustomStringConvertible {

  var _fd: Int32
  public let path: String

  // Lower level constructor. The validity of the fd parameter is not checked.
  public init(path: String, fd: Int32) {
    self.path = path
    self._fd = fd
  }

  public init(path: String, mode: FileOperation = .R) throws {
    self.path = path
    _fd = Sys.openFile(path, operation: mode)
    if _fd == -1 {
      throw FileError.Open
    }
  }

  public func printList(string: String) {
    // 10 - new line
    write(string)
    if string.isEmpty || string.utf16.codeUnitAt(string.utf16.count - 1) != 10 {
      let a: [UInt8] = [10]
      writeBytes(a, maxBytes: a.count)
    }
  }

  public func print(v: String) {
    write(v)
  }

  public func read(maxBytes: Int = -1) throws -> String? {
    if maxBytes < 0 {
      let a = try readAllCChar()
      return String.fromCharCodes(a)
    } else {
      var a = [CChar](count: maxBytes, repeatedValue: 0)
      try readCChar(&a, maxBytes: maxBytes)
      return String.fromCharCodes(a)
    }
  }

  public func readBytes(inout buffer: [UInt8], maxBytes: Int) throws -> Int {
    return try doRead(&buffer, maxBytes: maxBytes)
  }

  public func readAllBytes() throws -> [UInt8] {
    var a = [UInt8](count: length, repeatedValue: 0)
    let n = try readBytes(&a, maxBytes: a.count)
    if n != a.count {
      throw FileError.Read
    }
    return a
  }

  public func readCChar(inout buffer: [CChar], maxBytes: Int) throws -> Int {
    return try doRead(&buffer, maxBytes: maxBytes)
  }

  public func readAllCChar() throws -> [CChar] {
    var a = [CChar](count: length, repeatedValue: 0)
    let n = try readCChar(&a, maxBytes: a.count)
    if n != a.count {
      throw FileError.Read
    }
    return a
  }

  public func readLines() throws -> [String?] {
    var r: [String?] = []
    let a = try readAllCChar()
    var si = 0
    for i in 0..<a.count {
      if a[i] == 10 {
        r.append(String.fromCharCodes(a, start: si, end: i))
        si = i + 1
      }
    }
    return r
  }

  public func write(string: String) -> Int {
    return Sys.writeString(_fd, string: string)
  }

  public func writeBytes(bytes: [UInt8], maxBytes: Int) -> Int {
    return Sys.write(_fd, address: bytes, length: maxBytes)
  }

  public func writeCChar(bytes: [CChar], maxBytes: Int) -> Int {
    return Sys.write(_fd, address: bytes, length: maxBytes)
  }

  public func flush() {
    // Not implemented yet.
  }

  public func close() {
    if _fd != -1 {
      Sys.close(_fd)
    }
    _fd = -1
  }

  public var isOpen: Bool { return _fd != -1 }

  public var fd: Int32 { return _fd }

  public func doRead(address: UnsafeMutablePointer<Void>, maxBytes: Int) throws
      -> Int {
    assert(maxBytes >= 0)
    let n = Sys.read(_fd, address: address, length: maxBytes)
    if n == -1 {
      throw FileError.Read
    }
    return n
  }

  func seek(offset: Int, whence: Int32) -> Int {
    return Sys.lseek(_fd, offset: offset, whence: whence)
  }

  public var position: Int {
    get {
      return seek(0, whence: PosixSys.SEEK_CUR)
    }
    set(value) {
      seek(value, whence: PosixSys.SEEK_SET)
    }
  }

  public var length: Int {
    let current = position
    if current == -1 {
      return -1
    } else {
      let end = seek(0, whence: PosixSys.SEEK_END)
      position = current
      return end
    }
  }

  public static func open(path: String, mode: FileOperation = .R,
      fn: ((f: File) -> Void )?) throws -> File {
    let f = try File(path: path, mode: mode)
    defer {
      f.close()
    }
    if let af = fn {
      af(f: f)
    }
    return f
  }

  public static func exists(path: String) -> Bool {
    var buf = Sys.statBuffer()
    return Sys.stat(path, buffer: &buf) == 0
  }

  public static func stat(path: String) -> Stat? {
    var buf = Sys.statBuffer()
    return Sys.stat(path, buffer: &buf) == 0 ? Stat(buffer: buf) : nil
  }

  public static func delete(path: String) throws {
    if Sys.unlink(path) == -1 {
      throw FileError.Delete
    }
  }

  public static func rename(oldPath: String, newPath: String) throws {
    if Sys.rename(oldPath, newPath: newPath) == -1 {
      throw FileError.Rename
    }
  }

  public var description: String { return "File(path: \(inspect(path)))" }

}


public enum FileError: ErrorType {
  case Open
  case Delete
  case Rename
  case Read
}


// The file will be closed and removed automatically when it can be garbage
// collected.
//
// The file will be created with the file mode of read/write by the user.
//
// **Note**: If the process is cancelled (CTRL+C) or does not terminate
// normally, the files may not be removed automatically.
public class TempFile: File {

  init(prefix: String = "", suffix: String = "", directory: String? = nil)
      throws {
    var d = "/tmp/"
    if let ad = directory {
      d = ad
      let len = d.utf16.count
      if len == 0 || d.utf16.codeUnitAt(len - 1) != 47 { // /
        d += "/"
      }
    }

    var fd: Int32 = -1
    var attempts = 0
    var path = ""
    while fd == -1 {
      path = "\(d)\(prefix)\(RNG().nextUInt64())\(suffix)"
      fd = Sys.openFile(path, operation: .W, mode: PosixSys.USER_RW_FILE_MODE)
      if attempts >= 100 {
        throw TempFileError.Create(message: "Too many attempts.")
      } else if attempts % 10 == 0 {
        IO.sleep(0.00000001)
      }
      attempts += 1
    }

    super.init(path: path, fd: fd)
  }

  deinit {
    closeAndUnlink()
  }

  public func closeAndUnlink() {
    close()
    Sys.unlink(path)
  }

}


public enum TempFileError: ErrorType {
  case Create(message: String)
}
