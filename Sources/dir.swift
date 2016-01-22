

public struct DirImpl {

  public var cwd: String? {
    return Sys.cwd
  }

  public subscript(pattern: String) -> [(String, FileType, String)] {
    var r = [(String, FileType, String)]()
    do {
      var list = try FileGlobList(pattern: pattern) { name, type, path in
        r.append((name, type, path))
      }
      try list.list()
    } catch {
      // Ignore it, since subscript cannot throw. Users can use FileGlobList
      // directly if they want to try to catch the errors.
      // These errors could also be caused by trying to open directories that
      // are inaccessible.
    }
    return r
  }

}


let Dir = DirImpl()
