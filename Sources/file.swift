

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
    _fd = Sys.openFile(filePath: path, operation: mode)
    if _fd == -1 {
      throw FileError.Open
    }
  }

  deinit { close() }

  public func printList(string: String) {
    // 10 - new line
    let _ = write(string: string)
    if string.isEmpty ||
        string.utf16.codeUnitAt(index: string.utf16.count - 1) != 10 {
      let a: [UInt8] = [10]
      let _ = writeBytes(bytes: a, maxBytes: a.count)
    }
  }

  public func print(v: String) {
    let _ = write(string: v)
  }

  public func read(maxBytes: Int = -1) throws -> String? {
    if maxBytes < 0 {
      let a = try readAllCChar()
      return String.fromCharCodes(charCodes: a)
    } else {
      var a = [CChar](repeating: 0, count: maxBytes)
      let _ = try readCChar(buffer: &a, maxBytes: maxBytes)
      return String.fromCharCodes(charCodes: a)
    }
  }

  public func readBytes(buffer: inout [UInt8], maxBytes: Int) throws -> Int {
    return try doRead(address: &buffer, maxBytes: maxBytes)
  }

  public func readAllBytes() throws -> [UInt8] {
    var a = [UInt8](repeating: 0, count: length)
    let n = try readBytes(buffer: &a, maxBytes: a.count)
    if n != a.count {
      throw FileError.Read
    }
    return a
  }

  public func readCChar(buffer: inout [CChar], maxBytes: Int) throws -> Int {
    return try doRead(address: &buffer, maxBytes: maxBytes)
  }

  public func readAllCChar() throws -> [CChar] {
    var a = [CChar](repeating: 0, count: length)
    let n = try readCChar(buffer: &a, maxBytes: a.count)
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
        r.append(String.fromCharCodes(charCodes: a, start: si, end: i))
        si = i + 1
      }
    }
    return r
  }

  public func write(string: String) -> Int {
    return Sys.writeString(fd: _fd, string: string)
  }

  public func writeBytes(bytes: [UInt8], maxBytes: Int) -> Int {
    return Sys.write(fd: _fd, address: bytes, length: maxBytes)
  }

  public func writeCChar(bytes: [CChar], maxBytes: Int) -> Int {
    return Sys.write(fd: _fd, address: bytes, length: maxBytes)
  }

  public func flush() {
    // Not implemented yet.
  }

  public func close() {
    if _fd != -1 {
      let _ = Sys.close(fd: _fd)
    }
    _fd = -1
  }

  public var isOpen: Bool { return _fd != -1 }

  public var fd: Int32 { return _fd }

  public func doRead(address: UnsafeMutablePointer<Void>, maxBytes: Int) throws
      -> Int {
    assert(maxBytes >= 0)
    let n = Sys.read(fd: _fd, address: address, length: maxBytes)
    if n == -1 {
      throw FileError.Read
    }
    return n
  }

  func seek(offset: Int, whence: Int32) -> Int {
    return Sys.lseek(fd: _fd, offset: offset, whence: whence)
  }

  public var position: Int {
    get {
      return seek(offset: 0, whence: PosixSys.SEEK_CUR)
    }
    set(value) {
      let _ = seek(offset: value, whence: PosixSys.SEEK_SET)
    }
  }

  public var length: Int {
    let current = position
    if current == -1 {
      return -1
    } else {
      let end = seek(offset: 0, whence: PosixSys.SEEK_END)
      position = current
      return end
    }
  }

  public var description: String { return "File(path: \(inspect( path)))" }

  public static func open(path: String, mode: FileOperation = .R,
      fn: (f: File) throws -> Void) throws {
    let f = try File(path: path, mode: mode)
    defer { f.close() }
    try fn(f: f)
  }

  public static func exists(path: String) -> Bool {
    var buf = Sys.statBuffer()
    return Sys.stat(path: path, buffer: &buf) == 0
  }

  public static func stat(path: String) -> Stat? {
    var buf = Sys.statBuffer()
    return Sys.stat(path: path, buffer: &buf) == 0 ? Stat(buffer: buf) : nil
  }

  public static func delete(path: String) throws {
    if Sys.unlink(path: path) == -1 {
      throw FileError.Delete
    }
  }

  public static func rename(oldPath: String, newPath: String) throws {
    if Sys.rename(oldPath: oldPath, newPath: newPath) == -1 {
      throw FileError.Rename
    }
  }

  // Aliases for handy FilePath methods.
  public static func join(firstPath: String, _ secondPath: String) -> String {
    return FilePath.join(firstPath, secondPath)
  }

  public static func baseName(path: String, suffix: String? = nil) -> String {
    return FilePath.baseName(path: path, suffix: suffix)
  }

  public static func dirName(path: String) -> String {
    return FilePath.dirName(path: path)
  }

  public static func extName(path: String) -> String {
    return FilePath.extName(path: path)
  }

  public static func expandPath(path: String) throws -> String {
    return try FilePath.expandPath(path: path)
  }

}


public enum FileError: ErrorProtocol {
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
      if len == 0 || d.utf16.codeUnitAt(index: len - 1) != 47 { // /
        d += "/"
      }
    }

    var fd: Int32 = -1
    var attempts = 0
    var path = ""
    while fd == -1 {
      path = "\(d)\(prefix)\(RNG().nextUInt64())\(suffix)"
      fd = Sys.openFile(filePath: path, operation: .W,
          mode: PosixSys.USER_RW_FILE_MODE)
      if attempts >= 100 {
        throw TempFileError.Create(message: "Too many attempts.")
      } else if attempts % 10 == 0 {
        IO.sleep(seconds: 0.00000001)
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
    let _ = Sys.unlink(path: path)
  }

}


public enum TempFileError: ErrorProtocol {
  case Create(message: String)
}


public class FilePath {

  public static func join(_ firstPath: String, _ secondPath: String) -> String {
    let fpa = firstPath.bytes
    let i = skipTrailingSlashes(bytes: fpa, lastIndex: fpa.count - 1)
    let fps = String.fromCharCodes(charCodes: fpa, start: 0, end: i) ?? ""
    if !secondPath.isEmpty && secondPath.utf16.codeUnitAt(index: 0) == 47 { // /
      return "\(fps)\(secondPath)"
    }
    return "\(fps)/\(secondPath)"
  }

  public static func skipTrailingSlashes(bytes: [UInt8], lastIndex: Int)
      -> Int {
    var i = lastIndex
    while i >= 0 && bytes[i] == 47 { // /
      i -= 1
    }
    return i
  }

  public static func skipTrailingChars(bytes: [UInt8], lastIndex: Int) -> Int {
    var i = lastIndex
    while i >= 0 && bytes[i] != 47 { // /
      i -= 1
    }
    return i
  }

  public static func baseName(path: String, suffix: String? = nil) -> String {
    let bytes = path.bytes
    let len = bytes.count
    var ei = skipTrailingSlashes(bytes: bytes, lastIndex: len - 1)
    if ei >= 0 {
      var si = 0
      if ei > 0 {
        si = skipTrailingChars(bytes: bytes, lastIndex: ei - 1) + 1
      }
      if let sf = suffix {
        ei = skipSuffix(bytes: bytes, suffix: sf, lastIndex: ei)
      }
      return String.fromCharCodes(charCodes: bytes, start: si, end: ei) ?? ""
    }
    return "/"
  }

  public static func skipSuffix(bytes: [UInt8], suffix: String, lastIndex: Int)
      -> Int {
    var a = suffix.bytes
    var i = lastIndex
    var j = a.count - 1
    while i >= 0 && j >= 0 && bytes[i] == a[j] {
      i -= 1
      j -= 1
    }
    return j < 0 ? i : lastIndex
  }

  public static func dirName(path: String) -> String {
    let bytes = path.bytes
    let len = bytes.count
    var i = skipTrailingSlashes(bytes: bytes, lastIndex: len - 1)
    if i > 0 {
      //var ei = i
      i = skipTrailingChars(bytes: bytes, lastIndex: i - 1)
      let ci = i
      i = skipTrailingSlashes(bytes: bytes, lastIndex: i - 1)
      if i >= 0 {
        return String.fromCharCodes(charCodes: bytes, start: 0, end: i) ?? ""
      } else if ci > 0 {
        return String.fromCharCodes(charCodes: bytes, start: ci - 1,
            end: len - 1) ?? ""
      } else if ci == 0 {
        return "/"
      }
    } else if i == 0 {
      // Ignore.
    } else {
      return String.fromCharCodes(charCodes: bytes,
          start: len - (len > 1 ? 2 : 1), end: len) ?? ""
    }
    return "."
  }

  public static func extName(path: String) -> String {
    let bytes = path.bytes
    var i = bytes.count - 1
    if bytes[i] != 46 {
      while i >= 0 && bytes[i] != 46 { // Skip trailing chars.
        i -= 1
      }
      return String.fromCharCodes(charCodes: bytes, start: i) ?? ""
    }
    return ""
  }

  public static func skipSlashes(bytes: [UInt8], startIndex: Int,
      maxBytes: Int) -> Int {
    var i = startIndex
    while i < maxBytes && bytes[i] == 47 {
      i += 1
    }
    return i
  }

  public static func skipChars(bytes: [UInt8], startIndex: Int,
      maxBytes: Int) -> Int {
    var i = startIndex
    while i < maxBytes && bytes[i] != 47 {
      i += 1
    }
    return i
  }

  static func checkHome(path: String?) throws -> String {
    if let hd = path {
      return hd
    } else {
      throw FilePathError.ExpandPath(message: "Invalid home directory.")
    }
  }

  public static func expandPath(path: String) throws -> String {
    let bytes = path.bytes
    let len = bytes.count
    if len > 0 {
      var i = 0
      let fc = bytes[0]
      if fc == 126 { // ~
        var homeDir = ""
        if len == 1 || bytes[1] == 47 { // /
          homeDir = try checkHome(path: IO.env["HOME"])
          i = 1
        } else {
          i = skipChars(bytes: bytes, startIndex: 1, maxBytes: len)
          if let name = String.fromCharCodes(charCodes: bytes, start: 1,
              end: i - 1) {
            if let ps = Sys.getpwnam(name: name) {
              homeDir = try checkHome(path: String(cString: ps.pointee.pw_dir))
            } else {
              throw FilePathError.ExpandPath(message: "User does not exist.")
            }
          } else {
            throw FilePathError.ExpandPath(message: "Invalid name.")
          }
        }
        if i >= len {
          return homeDir
        }
        return join(homeDir, doExpandPath(bytes: bytes, startIndex: i,
            maxBytes: len))
      } else if fc != 47 { // /
        if let cd = Dir.cwd {
          if fc == 46 { // .
            let za = join(cd, path).bytes
            return doExpandPath(bytes: za, startIndex: 0, maxBytes: za.count)
          }
          return join(cd, doExpandPath(bytes: bytes, startIndex: 0,
              maxBytes: len))
        } else {
          throw FilePathError.ExpandPath(message: "Invalid current directory.")
        }
      }
      return doExpandPath(bytes: bytes, startIndex: i, maxBytes: len)
    }
    return ""
  }

  public static func doExpandPath(bytes: [UInt8], startIndex: Int,
      maxBytes: Int) -> String {
    var i = startIndex
    var a = [String]()
    var ai = -1
    var sb = ""
    func add() {
      let si = i
      i = skipChars(bytes: bytes, startIndex: i + 1, maxBytes: maxBytes)
      ai += 1
      let s = String.fromCharCodes(charCodes: bytes, start: si,
          end: i - 1) ?? ""
      if ai < a.count {
        a[ai] = s
      } else {
        a.append(s)
      }
      i = skipSlashes(bytes: bytes, startIndex: i + 1, maxBytes: maxBytes)
    }
    func stepBack() {
      if ai >= 0 {
        ai -= 1
      }
      i = skipSlashes(bytes: bytes, startIndex: i + 2, maxBytes: maxBytes)
    }
    if maxBytes > 0 {
      let lasti = maxBytes - 1
      while i < maxBytes && bytes[i] == 47 { //
        sb += "/"
        i += 1
      }
      if i >= maxBytes {
        return sb
      }
      while i < maxBytes {
        var c = bytes[i]
        if c == 46 { // .
          if i < lasti {
            c = bytes[i + 1]
            if c == 46 { // ..
              if i < lasti - 1 {
                c = bytes[i + 2]
                if c == 47 { // /
                  stepBack()
                } else {
                  add()
                }
              } else {
                stepBack()
              }
            } else if c == 47 { // /
              i = skipSlashes(bytes: bytes, startIndex: i + 2,
                  maxBytes: maxBytes)
            } else {
              add()
            }
          } else {
            break
          }
        } else {
          add()
        }
      }
      var slash = false
      for i in 0...ai {
        if slash {
          sb += "/"
        }
        sb += a[i]
        slash = true
      }
      if bytes[lasti] == 47 { // /
        sb += "/"
      }
    }
    return sb
  }

}


enum FilePathError: ErrorProtocol {
  case ExpandPath(message: String)
}


public class FileStream {

  public var fp: CFilePointer?
  let SIZE = 80 // Starting buffer size.

  public init(fp: CFilePointer) {
    self.fp = fp
  }

  deinit { close() }

  public func close() {
    if let afp = fp {
      let _ = Sys.fclose(fp: afp)
    }
    fp = nil
  }

  public func readAllCChar() throws -> [CChar] {
    guard let afp = fp else { return [CChar]() }
    var a = [CChar](repeating: 0, count: SIZE)
    var buffer = [CChar](repeating: 0, count: SIZE)
    var alen = SIZE
    var j = 0
    while Sys.fgets(buffer: &buffer, length: Int32(SIZE), fp: afp) != nil {
      for i in 0..<SIZE {
        let c = buffer[i]
        if c == 0 {
          break
        }
        if j >= alen {
          var b = [CChar](repeating: 0, count: alen * 8)
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

  public func readLines(fn: (string: String?) -> Void) throws {
    guard let afp = fp else { return }
    var a = [CChar](repeating: 0, count: SIZE)
    var buffer = [CChar](repeating: 0, count: SIZE)
    var alen = SIZE
    var j = 0
    while Sys.fgets(buffer: &buffer, length: Int32(SIZE), fp: afp) != nil {
      var i = 0
      while i < SIZE {
        let c = buffer[i]
        if c == 0 {
          break
        }
        if j >= alen {
          var b = [CChar](repeating: 0, count: alen * 8)
          for m in 0..<alen {
            b[m] = a[m]
          }
          a = b
          alen = b.count
        }
        a[j] = c
        if c == 10 {
          fn(string: String.fromCharCodes(charCodes: a, start: 0, end: j))
          j = 0
        } else {
          j += 1
        }
        i += 1
      }
    }
    if j > 0 {
      fn(string: String.fromCharCodes(charCodes: a, start: 0, end: j - 1))
    }
  }

  public func readByteLines(maxBytes: Int = 80,
      fn: (bytes: [UInt8], length: Int) -> Void) throws {
    guard let afp = fp else { return }
    var buffer = [UInt8](repeating: 0, count: Int(maxBytes))
    while true {
      let n = Sys.fread(buffer: &buffer, size: 1, nmemb: maxBytes, fp: afp)
      if n > 0 {
        fn(bytes: buffer, length: n)
      } else {
        break
      }
    }
  }

}
