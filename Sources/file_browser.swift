
public enum FileType {
  case D // Directory
  case F // File
  case U // Unknown
}


public typealias FileBrowserHandler =
    (name: String, type: FileType, path: String) throws -> Void


final public class FileBrowser {

  var dirp: COpaquePointer?
  var entry: CDirentPointer?

  public init(path: String) throws {
    dirp = Sys.opendir(path)
    if dirp == nil {
      throw FileBrowserError.InvalidDirectory(message:
          "Failed to open directory.")
    }
  }

  // The array needs to include a null value (0) at the end.
  public init(pathBytes: [UInt8]) throws {
    dirp = Sys.opendir(pathBytes)
    if dirp == nil {
      throw FileBrowserError.InvalidDirectory(message:
          "Failed to open directory.")
    }
  }

  deinit {
    close()
  }

  public func next() -> Bool {
    guard let dp = dirp else { return false }
    // Funny stuff. If the code was entry = Sys.readdir(dp), at the end of the
    // listing the entry would still not be set to nil. By storing it into The
    // temp variable "e" first, we get it to behave correctly.
    let e = Sys.readdir(dp)
    entry = e
    return e != nil
  }

  public func close() {
    if let dp = dirp {
      Sys.closedir(dp)
      dirp = nil
    }
  }

  public var name: String? {
    var dirName = entry!.memory.d_name
    return withUnsafePointer(&dirName) { (ptr) -> String? in
      return String.fromCString(UnsafePointer<CChar>(ptr))
    }
  }

  public var nameBytes: [UInt8] {
    var dirName = entry!.memory.d_name
    return withUnsafePointer(&dirName) { (ptr) -> [UInt8] in
      let len = Int(Sys.strlen(UnsafePointer<CChar>(ptr)))
      let b = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(ptr),
          count: len)
      return [UInt8](b)
    }
  }

  public var rawEntry: CDirentPointer {
    return entry!
  }

  public var type: FileType {
    let t = entry!.memory.d_type
    return t == 8 ? .F : (t == 4 ? .D : .U)
  }

  public var rawType: UInt8 {
    return entry!.memory.d_type
  }

  public var ino: UInt {
    return entry!.memory.d_ino
  }

  public static func scanDir(path: String,
      fn: (name: String, type: FileType) throws -> Void) throws {
    let fb = try FileBrowser(path: path)
    while fb.next() {
      try fn(name: fb.name ?? "", type: fb.type)
    }
  }

  public static func recurseDir(path: String, fn: FileBrowserHandler) {
    let lasti = path.utf16.count - 1
    if lasti >= 0 {
      if path.utf16.codeUnitAt(lasti) != 47 { // /
        doRecurseDir("\(path)/", fn: fn)
      } else {
        doRecurseDir(path, fn: fn)
      }
    }
  }

  public static func doRecurseDir(path: String, fn: FileBrowserHandler) {
    do {
      try scanDir(path) { (name, type) in
        if name != ".." && name != "." {
          try fn(name: name, type: type, path: path)
          if type == .D {
            doRecurseDir("\(path)\(name)/", fn: fn)
          }
        }
      }
    } catch { //FileBrowserError.InvalidDirectory
      // Silence errors in case of directories that cannot be opened.
    }
  }

}


public enum FileBrowserError: ErrorType {
  case InvalidDirectory(message: String)
}
