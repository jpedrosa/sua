
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

  public static func scanDir(dirPath: String,
      fn: (name: String, type: FileType) -> Void) throws {
    var dirp = Sys.opendir(dirPath)
    if (dirp == nil) {
      throw FileBrowserError.InvalidDirectory(message:
          "Failed to open directory.")
    }
    defer {
      Sys.closedir(dirp)
    }
    var entry = Sys.readdir(dirp)
    while entry != nil {
      var dirName = entry.memory.d_name
      let name = withUnsafePointer(&dirName) { (ptr) -> String in
        return String.fromCString(UnsafePointer<CChar>(ptr)) ?? ""
      }
      let t = entry.memory.d_type
      fn(name: name, type: t == 8 ? .F : (t == 4 ? .D : .U))
      entry = Sys.readdir(dirp)
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
