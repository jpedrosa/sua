

public struct DirImpl {

  public var cwd: String? {
    return Sys.cwd
  }

  public subscript(pattern: String) -> [(String, FileType, String)] {
    do {
      return try globList(pattern)
    } catch {
      // Ignore it, since subscript cannot throw. Users can use FileGlobList
      // directly if they want to try to catch the errors.
      // These errors could also be caused by trying to open directories that
      // are inaccessible.
    }
    return []
  }

  public func globList(pattern: String, skipDotFiles: Bool = true,
      ignoreCase: Bool = false) throws -> [(String, FileType, String)] {
    var r = [(String, FileType, String)]()
    try glob(pattern) { name, type, path in
      r.append((name, type, path))
    }
    return r
  }

  public func glob(pattern: String, skipDotFiles: Bool = true,
      ignoreCase: Bool = false, fn: FileBrowserHandler) throws {
    var list = try FileGlobList(pattern: pattern, skipDotFiles: skipDotFiles,
        ignoreCase: ignoreCase, fn: fn)
    try list.list()
  }

}


public let Dir = DirImpl()
