

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

  var parts = [FileGlobPart]()
  var ignoreCase = false

  public init(ignoreCase: Bool = false) {
    self.ignoreCase = ignoreCase
  }

  mutating func addLiteral(value: String) {
    parts.append(FileGlobStringPart(type: .Literal, value: value))
  }

  mutating func addSeparator() {
    parts.append(FileGlobTypePart(type: .Separator))
  }

  mutating func addAll() {
    parts.append(FileGlobTypePart(type: .All))
  }

  mutating func addRecurse() {
    parts.append(FileGlobTypePart(type: .Recurse))
  }

  mutating func addMatcher(glob: Glob) {
    parts.append(FileGlobMatcherPart(glob: glob))
  }

  public static func parse(string: String, ignoreCase: Bool = false) throws
      -> FileGlob {
    var stream = ByteStream(bytes: string.bytes)
    var fg = FileGlob(ignoreCase: ignoreCase)
    while !stream.isEol {
      if stream.eatWhileNeitherTwo(47, c2: 42) { // / *
        if stream.matchSlash() {
          if let s = stream.collectTokenString() {
            fg.addLiteral(s)
          } else {
            throw FileGlobError.Parse
          }
        } else {
          stream.eatUntilOne(47) // /
          if let s = stream.collectTokenString() {
            fg.addMatcher(try Glob.parse(s, ignoreCase: ignoreCase))
          } else {
            throw FileGlobError.Parse
          }
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
            if let s = stream.collectTokenString() {
              fg.addMatcher(try Glob.parse(s, ignoreCase: ignoreCase))
            } else {
              throw FileGlobError.Parse
            }
          }
        } else if stream.matchSlash() || stream.isEol {
          fg.addAll()
        } else { // Ends with.
          stream.eatUntilOne(47) // /
          if let s = stream.collectTokenString() {
            fg.addMatcher(try Glob.parse(s, ignoreCase: ignoreCase))
          } else {
            throw FileGlobError.Parse
          }
        }
      } else {
        throw FileGlobError.Unreachable
      }
    }

    return fg
  }

}


enum FileGlobError: ErrorType {
  case Parse
  case Unreachable
}
