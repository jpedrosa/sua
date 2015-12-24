
public enum FileType {
  case D
  case F
  case U
  case Directory
  case File
  case Unknown

  public static func translate(type: FileType) -> String {
    return type == .F ? "f" : (type == .D ? "d" : "?")
  }

}


public class FileBrowser {

  var dirp: COpaquePointer?
  var entry: DirentEntry?

  public init(path: String) throws {
    dirp = Sys.opendir(path)
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

  var entryName: String? {
    var dirName = entry!.memory.d_name
    return withUnsafePointer(&dirName) { (ptr) -> String? in
      return String.fromCString(UnsafePointer<CChar>(ptr))
    }
  }

  var entryType: FileType {
    let t = entry!.memory.d_type
    return t == 8 ? .F : (t == 4 ? .D : .U)
  }

  public static func scanDir(dirPath: String,
      fn: (name: String, type: FileType) -> Void) throws {
    let fb = try FileBrowser(path: dirPath)
    while fb.next() {
      fn(name: fb.entryName ?? "", type: fb.entryType)
    }
  }

  public static func recurseDir(dirPath: String,
      fn: (name: String, type: FileType, dirPath: String) -> Void) {
    let a = [UInt8](dirPath.utf8)
    let lasti = a.count - 1
    if lasti >= 0 {
      if a[lasti] != 47 { // /
        doRecurseDir("\(dirPath)/", fn: fn)
      } else {
        doRecurseDir(dirPath, fn: fn)
      }
    }
  }

  public static func doRecurseDir(dirPath: String,
      fn: (name: String, type: FileType, dirPath: String) -> Void) {
    do {
      try scanDir(dirPath) { (name, type) in
        if name != ".." && name != "." {
          fn(name: name, type: type, dirPath: dirPath)
          if type == .D {
            doRecurseDir("\(dirPath)\(name)/", fn: fn)
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
