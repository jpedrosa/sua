

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
          if stream.matchSlash() {
            fg.addRecurse()
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
