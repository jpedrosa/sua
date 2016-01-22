

public enum FileGlobType {
  case Literal
  case All
  case EndsWith
  case Matcher
  case Recurse
  case Separator
}


public protocol FileGlobPart {
  var type: FileGlobType { get }
}


public struct FileGlobStringPart: FileGlobPart {

  public var type: FileGlobType
  public var value: String

  public init(type: FileGlobType, value: String) {
    self.type = type
    self.value = value
  }

}


public struct FileGlobTypePart: FileGlobPart {

  public var type: FileGlobType

  public init(type: FileGlobType) {
    self.type = type
  }

}


public struct FileGlobMatcherPart: FileGlobPart {

  public var type: FileGlobType
  public var glob: Glob

  public init(glob: Glob) {
    type = .Matcher
    self.glob = glob
  }

}


public struct FileGlob {

  public var parts = [FileGlobPart]()
  var ignoreCase = false

  public init(ignoreCase: Bool = false) {
    self.ignoreCase = ignoreCase
  }

  public mutating func addLiteral(value: String) {
    parts.append(FileGlobStringPart(type: .Literal, value: value))
  }

  public mutating func addSeparator() {
    parts.append(FileGlobTypePart(type: .Separator))
  }

  public mutating func addAll() {
    parts.append(FileGlobTypePart(type: .All))
  }

  public mutating func addRecurse() {
    parts.append(FileGlobTypePart(type: .Recurse))
  }

  public mutating func addMatcher(glob: Glob) {
    parts.append(FileGlobMatcherPart(glob: glob))
  }

  public mutating func addEndsWith(value: String) {
    parts.append(FileGlobStringPart(type: .EndsWith, value: value))
  }

  public static func parse(string: String, ignoreCase: Bool = false) throws
      -> FileGlob {
    var stream = ByteStream(bytes: string.bytes)
    var fg = FileGlob(ignoreCase: ignoreCase)
    func collectGlob() throws {
      let tb = stream.collectToken()
      let tokens = try GlobLexer(bytes: tb).parseAllGlobTokens()
      if tokens.count == 1 && tokens[0].globType == .Name {
        if let z = tokens[0].collectString() {
          if ignoreCase {
            if let ds = Ascii.toLowerCase(z) {
              fg.addLiteral(ds)
            } else {
              throw FileGlobError.Parse
            }
          } else {
            fg.addLiteral(z)
          }
        } else {
          throw FileGlobError.Parse
        }
      } else if tokens.count == 2 && tokens[0].globType == .SymAsterisk &&
          tokens[1].globType == .Name {
        if let z = tokens[1].collectString() {
          if ignoreCase {
            if let ds = Ascii.toLowerCase(z) {
              fg.addEndsWith(ds)
            } else {
              throw FileGlobError.Parse
            }
          } else {
            fg.addEndsWith(z)
          }
        } else {
          throw FileGlobError.Parse
        }
      } else {
        var m = try GlobMatcher.doParse(tokens)
        m.ignoreCase = ignoreCase
        fg.addMatcher(Glob(matcher: m.assembleMatcher(),
              ignoreCase: ignoreCase))
      }
    }
    while !stream.isEol {
      if stream.eatWhileNeitherTwo(47, c2: 42) { // / *
        if stream.matchSlash() {
          try collectGlob()
        } else {
          stream.eatUntilOne(47) // /
          try collectGlob()
        }
      } else if stream.eatSlash() {
        fg.addSeparator()
        stream.startIndex = stream.currentIndex
      } else if stream.eatAsterisk() {
        if stream.eatAsterisk() {
          if stream.matchSlash(){
            fg.addRecurse()
            stream.startIndex = stream.currentIndex
          } else if stream.isEol {
            fg.addAll()
            stream.startIndex = stream.currentIndex
          } else {
            stream.eatUntilOne(47) // /
            try collectGlob()
          }
        } else if stream.matchSlash() || stream.isEol {
          fg.addAll()
        } else { // Ends with.
          stream.eatUntilOne(47) // /
          try collectGlob()
        }
      } else {
        throw FileGlobError.Unreachable
      }
    }

    return fg
  }

}


public enum FileGlobError: ErrorType {
  case Parse
  case Unreachable
}


// This has been tested against the output of the globbing features of Ruby,
// and where possible we have tried to match it.
public struct FileGlobList {

  var fileGlob: FileGlob
  var ignoreCase = false
  var skipDotFiles = true
  var handler: FileBrowserHandler
  var lastIndex: Int
  var parts: [FileGlobPart]

  public init(fileGlob: FileGlob, skipDotFiles: Bool = true,
        fn: FileBrowserHandler) {
    self.fileGlob = fileGlob
    self.skipDotFiles = skipDotFiles
    ignoreCase = fileGlob.ignoreCase
    handler = fn
    lastIndex = 0
    parts = []
  }

  public init(pattern: String, skipDotFiles: Bool = true,
      ignoreCase: Bool = false,
      fn: FileBrowserHandler) throws {
    self.init(fileGlob: try FileGlob.parse(pattern, ignoreCase: ignoreCase),
        skipDotFiles: skipDotFiles, fn: fn)
  }

  public mutating func list() throws {
    let len = fileGlob.parts.count
    if len > 0 {
      var i = 0
      var baseDir = ""
      while i < len {
        let part = fileGlob.parts[i]
        if part.type == .Separator {
          baseDir += "/"
        } else if part.type == .Literal {
          baseDir += (part as! FileGlobStringPart).value
        } else {
          break
        }
        i += 1
      }
      if baseDir.isEmpty {
        baseDir = Dir.cwd ?? ""
      }
      if baseDir.utf16.codeUnitAt(baseDir.utf16.count - 1) != 47 { // /
        baseDir += "/"
      }
      if parts.count == 0 {
        var lastWasRecurse = false
        while i < len {
          let part = fileGlob.parts[i]
          if part.type != .Separator {
            if !lastWasRecurse {
              parts.append(part)
            }
            if part.type == .Recurse {
              lastWasRecurse = true
            }
          } else {
            lastWasRecurse = false
          }
          i += 1
        }
        lastIndex = parts.count - 1
      }
      if lastIndex >= 0 {
        try doList(baseDir, partIndex: 0)
      } else {
        // Perhaps a literal file or directory was given, so return it instead:
        var z = ""
        for part in fileGlob.parts {
          if part.type == .Separator {
            z += "/"
          } else if part.type == .Literal {
            z += (part as! FileGlobStringPart).value
          }
        }
        if let st = File.stat(z) {
          let t: FileType = st.isRegularFile ? .F : (st.isDirectory ? .D : .U)
          try handler(name: File.baseName(z), type: t,
              path: "\(File.dirName(z))/")
        }
      }
    }
  }

  public mutating func doList(path: String, partIndex: Int) throws {
    let part = parts[partIndex]
    if part.type == .Recurse {
      if partIndex >= lastIndex {
        try handler(name: File.baseName(path), type: .D,
            path: "\(File.dirName(path))/")
        try recurseAndAddDirectories(path)
      } else if partIndex + 1 >= lastIndex {
        try recurseAndMatch(path, partIndex: partIndex + 1)
      } else {
        var j = partIndex + 2
        while j <= lastIndex {
          if parts[j].type == .Recurse {
            break
          }
          j += 1
        }
        if j >= lastIndex {
          var indexList = [Int]()
          try recurseAndMultiLevelMatch(path, partIndex: partIndex,
              indexList: &indexList)
        } else {
          var indexList = [Int]()
          try subRecurse(path, partIndex: partIndex, indexList: &indexList,
              lastMatchIndex: j - 1)
        }
      }
    } else { // .Matcher .EndsWith .Literal .All
      if partIndex < lastIndex {
        try FileBrowser.scanDir(path) { name, type in
          if type == .D {
            if self.matchFileName(name, partIndex: partIndex) {
              try self.doList("\(path)\(name)/", partIndex: partIndex + 1)
            }
          }
        }
      } else {
        try FileBrowser.scanDir(path) { name, type in
          if self.matchFileName(name, partIndex: partIndex) {
            try self.handler(name: name, type: type, path: path)
          }
        }
      }
    }
  }

  public func matchFileName(name: String, partIndex: Int) -> Bool {
    if self.skipDotFiles && name.utf16.codeUnitAt(0) == 46 { // .
      return false
    }
    let part = parts[partIndex]
    switch part.type {
      case .All:
        return true
      case .Matcher:
        var matcherPart = part as! FileGlobMatcherPart
        return matcherPart.glob.match(name)
      case .Literal:
        let stringPart = part as! FileGlobStringPart
        let s = ignoreCase ? Ascii.toLowerCase(name) ?? "" : name
        return s == stringPart.value
      case .EndsWith:
        let stringPart = part as! FileGlobStringPart
        let s = ignoreCase ? Ascii.toLowerCase(name) ?? "" : name
        return s.utf16.endsWith(stringPart.value)
      default:
        return false
    }
  }

  // This gets used on patterns like this: "/home/user/**/*.txt"
  public func recurseAndMatch(path: String, partIndex: Int) throws {
    try FileBrowser.scanDir(path) { name, type in
      if self.matchFileName(name, partIndex: partIndex) {
        try self.handler(name: name, type: type, path: path)
      }
      if type == .D {
        if self.skipDotFiles && name.utf16.codeUnitAt(0) == 46 { // .
          return
        }
        try self.recurseAndMatch("\(path)\(name)/", partIndex: partIndex)
      }
    }
  }

  // This is used for patterns like this: "/home/user/t_/**/"
  // It lists only the directories, recursively.
  public func recurseAndAddDirectories(path: String) throws {
    try FileBrowser.scanDir(path) { name, type in
      if type == .D {
        if self.skipDotFiles && name.utf16.codeUnitAt(0) == 46 { // .
          return
        }
        try self.handler(name: name, type: type, path: path)
        try self.recurseAndAddDirectories("\(path)\(name)/")
      }
    }
  }

  // This is used on patterns like this: "/home/user/**/d*/*.txt"
  public func recurseAndMultiLevelMatch(path: String, partIndex: Int,
      inout indexList: [Int]) throws {
    var indexListLen = indexList.count
    var haveIndexList = indexListLen > 0
    var finalMatcherIndex = partIndex + 1
    var haveFinalMatcher = false
    if haveIndexList {
      var mi = 0
      while mi < indexListLen {
        let n = indexList[mi]
        if n == lastIndex {
          finalMatcherIndex = n
          haveFinalMatcher = true
          break
        }
        mi += 1
      }
      if haveFinalMatcher {
        if indexListLen == 1 {
          haveIndexList = false
        } else {
          indexList.removeAtIndex(mi)
          indexListLen -= 1
        }
      }
    }
    try FileBrowser.scanDir(path) { name, type in
      if haveFinalMatcher &&
          self.matchFileName(name, partIndex: finalMatcherIndex) {
        try self.handler(name: name, type: type, path: path)
      }
      if type == .D && (!self.skipDotFiles || name.utf16.codeUnitAt(0) != 46) {
        let haveMatch = self.matchFileName(name, partIndex: partIndex + 1)
        var freshIndexList = [Int]()
        if haveIndexList {
          for mi in 0..<indexListLen {
            let n = indexList[mi]
            if self.matchFileName(name, partIndex: n) {
              freshIndexList.append(n + 1)
            }
          }
          if haveMatch {
            freshIndexList.append(partIndex + 2)
          }
        } else if haveMatch {
          freshIndexList.append(partIndex + 2)
        }
        try self.recurseAndMultiLevelMatch("\(path)\(name)/",
            partIndex: partIndex, indexList: &freshIndexList)
      }
    }
  }

  // This gets used for pattern like this "/home/**/user/**/t_"
  mutating public func subRecurse(path: String, partIndex: Int,
      inout indexList: [Int], lastMatchIndex: Int) throws {
    var indexListLen = indexList.count
    var haveIndexList = indexListLen > 0
    var finalMatcherIndex = partIndex + 1
    var haveFinalMatcher = false
    if haveIndexList {
      var mi = 0
      while mi < indexListLen {
        let n = indexList[mi]
        if n == lastMatchIndex {
          finalMatcherIndex = n
          haveFinalMatcher = true
          break
        }
        mi += 1
      }
      if haveFinalMatcher {
        if indexListLen == 1 {
          haveIndexList = false
        } else {
          indexList.removeAtIndex(mi)
          indexListLen -= 1
        }
      }
    }
    try FileBrowser.scanDir(path) { name, type in
      if type == .D && (!self.skipDotFiles || name.utf16.codeUnitAt(0) != 46) {
        let haveMatch = self.matchFileName(name, partIndex: partIndex + 1)
        if (haveMatch && (partIndex + 1 == lastMatchIndex)) ||
            (haveFinalMatcher && self.matchFileName(name,
                partIndex: finalMatcherIndex)) {
          try self.doList("\(path)\(name)/", partIndex: lastMatchIndex + 1)
        } else {
          var freshIndexList = [Int]()
          if haveIndexList {
            for mi in 0..<indexListLen {
              let n = indexList[mi]
              if self.matchFileName(name, partIndex: n) {
                freshIndexList.append(n + 1)
              }
            }
            if haveMatch {
              freshIndexList.append(partIndex + 2)
            }
          } else if haveMatch {
            freshIndexList.append(partIndex + 2)
          }
          try self.subRecurse("\(path)\(name)/", partIndex: partIndex,
              indexList: &freshIndexList, lastMatchIndex: lastMatchIndex)
        }
      }
    }
  }

}
