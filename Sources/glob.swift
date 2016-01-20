

public enum GlobTokenizer: Tokenizer {
  case OptionalNameComma
  case OptionalName
  case Set
  case SetNegation
  case SetMaybeEmpty
  case Body
  case Text
  case EscapeCharacter
}


public enum GlobTokenType: TokenType {
  case Text
  case Name
  case SymAsterisk           // *
  case SymQuestionMark       // ?
  case SymExclamation        // ! for negation of a set.
  case SetChar               // Non-range elements of a set.
  case SetRange              // a-z A-Z 0-9
  case SymOBSet              // [
  case SymCBSet              // ]
  case OptionalName
  case SymOBOptionalName     // {
  case SymComma  // ,
  case SymCBOptionalName     // }
}


public struct GlobToken: LexerToken, CustomStringConvertible {

  public var bytes: [UInt8]
  public var startIndex: Int
  public var endIndex: Int
  public var type: TokenType
  public var globType: GlobTokenType

}


public class GlobLexer: CommonLexer {

  typealias T = GlobTokenizer

  var escapeExitTokenizer = T.Body
  var escapeTokenType = GlobTokenType.Name

  init(bytes: [UInt8]) {
    super.init(bytes: bytes, status: CommonLexerStatus(tokenizer: T.Body))
  }

  override func next(tokenizer: Tokenizer) -> TokenType {
    switch(tokenizer as! GlobTokenizer) {
      case .OptionalNameComma:
        return inOptionalNameComma()
      case .OptionalName:
        return inOptionalName()
      case .Set:
        return inSet()
      case .SetNegation:
        return inSetNegation()
      case .SetMaybeEmpty:
        return inSetMaybeEmpty()
      case .EscapeCharacter:
        return inEscapeCharacter()
      case .Body:
        return inBody()
      case .Text:
        return inText()
    }
  }

  func isContextChar(c: UInt8) -> Bool {
    return c == 42 || c == 63 || c == 123 || c == 91 || c == 92 // * ? { [ \.
  }

  func inOptionalNameComma() -> GlobTokenType {
    if escape() {
      escapeExitTokenizer = T.OptionalNameComma
      escapeTokenType = .OptionalName
      return .OptionalName
    } else if stream.eatComma() {
      status.tokenizer = T.OptionalName
      return .SymComma
    } else if stream.eatCloseBrace() {
      status.tokenizer = T.Body
      return .SymCBOptionalName
    }
    stream.eatWhileNeitherThree(125, c2: 44, c3: 92)
    return .OptionalName
  }

  func inOptionalName() -> GlobTokenType {
    if escape() {
      escapeExitTokenizer = T.OptionalNameComma
      escapeTokenType = .OptionalName
      return .OptionalName
    } else if stream.eatCloseBrace() {
      status.tokenizer = T.Body
      return .SymCBOptionalName
    } else if stream.eatWhileNeitherThree(125, c2: 44, c3: 92) { // } , \.
      status.tokenizer = T.OptionalNameComma
      return .OptionalName
    }
    return inText() // Unexpected comma.
  }

  func inSet() -> GlobTokenType {
    status.tokenizer = T.Set
    if escape() {
      escapeExitTokenizer = T.Set
      escapeTokenType = .SetChar
      return .SetChar
    } else if stream.eatCloseBracket() {
      status.tokenizer = T.Body
      return .SymCBSet
    } else if stream.eatLowerCase() {
      if stream.eatMinus() {
        if stream.eatLowerCase() {
          return .SetRange
        }
        stream.currentIndex -= 1
      }
      return .SetChar
    } else if stream.eatUpperCase() {
      if stream.eatMinus() {
        if stream.eatUpperCase() {
          return .SetRange
        }
        stream.currentIndex -= 1
      }
      return .SetChar
    } else if stream.eatDigit() {
      if stream.eatMinus() {
        if stream.eatDigit() {
          return .SetRange
        }
        stream.currentIndex -= 1
      }
      return .SetChar
    }
    stream.next()
    return .SetChar
  }

  func inSetNegation() -> GlobTokenType {
    if stream.eatExclamation() {
      status.tokenizer = T.Set
      return .SymExclamation
    }
    return inSet()
  }

  func inSetMaybeEmpty() -> GlobTokenType {
    if stream.eatCloseBracket() {
      status.tokenizer = T.Body
      return .SymCBSet
    }
    return inSetNegation()
  }

  func inEscapeCharacter() -> GlobTokenType {
    status.tokenizer = escapeExitTokenizer
    stream.next()
    return escapeTokenType
  }

  func escape() -> Bool {
    if stream.eatBackslash() {
      if stream.currentIndex == stream.startIndex + 1 {
        stream.startIndex += 1
      }
      status.tokenizer = T.EscapeCharacter
      return true
    }
    return false
  }

  func inBody() -> GlobTokenType {
    if escape() { // \ Escape character.
      escapeExitTokenizer = T.Body
      escapeTokenType = .Name
      return .Name
    } else if stream.eatAsterisk() {
      stream.eatAsterisk()
      return .SymAsterisk
    } else if stream.eatQuestionMark() {
      return .SymQuestionMark
    } else if stream.eatOpenBrace() {
      status.tokenizer = T.OptionalName
      return .SymOBOptionalName
    } else if stream.eatOpenBracket() {
      status.tokenizer = T.SetMaybeEmpty
      return .SymOBSet
    }
    stream.eatUntil(isContextChar)
    return .Name
  }

  func inText() -> GlobTokenType {
    stream.skipToEnd()
    status.tokenizer = T.Text
    return .Text
  }

  func parseAllGlobTokens() throws -> [GlobToken] {
    var a = [GlobToken]()
    try parse() { tt in
      a.append(GlobToken(bytes: self.stream.bytes,
            startIndex: self.stream.startIndex,
            endIndex: self.stream.currentIndex,
            type: tt,
            globType: tt as! GlobTokenType))
    }
    return a
  }

}


public class Ascii {

  public static func toLowerCase(c: UInt8) -> UInt8 {
    if c >= 65 && c <= 90 {
      return c + 32
    }
    return c
  }

  public static func toLowerCase(bytes: [UInt8]) -> [UInt8] {
    var a = bytes
    let len = a.count
    for i in 0..<len {
      let c = a[i]
      if c >= 65 && c <= 90 {
        a[i] = c + 32
      }
    }
    return a
  }

  public static func toLowerCase(bytes: [[UInt8]]) -> [[UInt8]] {
    var a = bytes
    let len = a.count
    for i in 0..<len {
      let b = a[i]
      let blen = b.count
      for bi in 0..<blen {
        let c = b[bi]
        if c >= 65 && c <= 90 {
          a[i][bi] = c + 32
        }
      }
    }
    return a
  }

}


public enum GlobMatcherType {
  case Name
  case Any
  case One
  case Set
  case Alternative
}


public protocol GlobMatcherPart {
  var type: GlobMatcherType { get }
}


public struct GlobMatcherNamePart: GlobMatcherPart {

  public var type: GlobMatcherType
  public var bytes: [UInt8]

  public init(bytes: [UInt8]) {
    type = .Name
    self.bytes = bytes
  }

}


public struct GlobMatcherAnyPart: GlobMatcherPart {

  public var type = GlobMatcherType.Any

}


public struct GlobMatcherOnePart: GlobMatcherPart {

  public var type = GlobMatcherType.One

}


public struct GlobMatcherSetPart: GlobMatcherPart {

  public var type: GlobMatcherType
  public var chars: [UInt8]
  public var ranges: [UInt8]
  public var negated: Bool
  public var ignoreCase: Bool

  public init() {
    type = .Set
    chars = []
    ranges = []
    negated = false
    ignoreCase = false
  }

  public mutating func addChar(c: UInt8) {
    chars.append(c)
  }

  public mutating func addRange(c1: UInt8, c2: UInt8) {
    if c1 < c2 {
      ranges.append(c1)
      ranges.append(c2)
    } else {
      ranges.append(c2)
      ranges.append(c1)
    }
  }

  public mutating func negate() {
    negated = true
  }

  public func makeComparisonTable() -> FirstCharTable {
    var table = FirstCharTable(count: 256, repeatedValue: nil)
    for c in chars {
      let n = Int(ignoreCase ? Ascii.toLowerCase(c) : c)
      table[n] = FirstCharTableValue
    }
    var i = 0
    let len = ranges.count
    while i < len {
      var n = ranges[i]
      var n2 = ranges[i + 1]
      if ignoreCase {
        n = Ascii.toLowerCase(n)
        n2 = Ascii.toLowerCase(n2)
      }
      while n <= n2 {
        table[Int(n)] = FirstCharTableValue
        n += 1
      }
      i += 2
    }
    return table
  }

  public var isNegated: Bool {
    return negated
  }

}


public struct GlobMatcherAlternativePart: GlobMatcherPart {

  public var type: GlobMatcherType
  public var bytes: [[UInt8]]

  public init() {
    type = .Alternative
    bytes = []
  }

  public mutating func addBytes(bytes: [UInt8]) {
    self.bytes.append(bytes)
  }

}


// GlobMatcher will parse a ByteMatcher that can be used for matching from the
// start of a string. In order to allow for some flexibility, it will not match
// to the very end of a string by default, but it can be configured to do so by
// calling ByteMatcher#matchEos().
//
// E.g.
//     var bm = try GlobMatcher.parse("hello*.txt").assembleMatcher()
//     p(bm.match("hello_world.txta")) // Prints 15.
//
//     // If instead we call the matchEos on the ByteMatcher:
//     var bm2 = try GlobMatcher.parse("hello*.txt").assembleMatcher()
//     bm2.matchEos()
//     p(bm2.match("hello_world.txta")) // Prints -1. Not found. Since it didn't
//                                      // match it to the very end.
//
// The glob features that are understood are these:
//
//     * The ? wildcard - It will match a single character of any kind.
//
//     * The * wildcard - It will match any character until the next pattern is
//                        found.
//     * The [a-z] [abc] [A-Za-z0-9_] character set - It will match a character
//                        included in its ranges or sets.
//     * The [!a-z] [!def] character set negation. It will match a character
//                        that is not included in the set.
//     * The {jpg,png} optional names - It will match one of the names included
//                        in its list.
// The special characters could be escaped with the \ backslash character in
// order to allow them to work like any other character.
public struct GlobMatcher {

  var parts = [GlobMatcherPart]()
  var currentSet: GlobMatcherSetPart?
  var currentAlternative: GlobMatcherAlternativePart?
  public var ignoreCase = false

  public init() { }

  public mutating func addName(bytes: [UInt8]) {
    parts.append(GlobMatcherNamePart(bytes: bytes))
  }

  public mutating func addAny() {
    parts.append(GlobMatcherAnyPart())
  }

  public mutating func addOne() {
    parts.append(GlobMatcherOnePart())
  }

  public mutating func startSet() {
    currentSet = GlobMatcherSetPart()
  }

  public mutating func addSetChar(c: UInt8) {
    currentSet!.addChar(c)
  }

  public mutating func addSetRange(c1: UInt8, c2: UInt8) {
    currentSet!.addRange(c1, c2: c2)
  }

  public mutating func negateSet() {
    currentSet!.negate()
  }

  public mutating func saveSet() {
    if let cs = currentSet {
      if cs.ranges.count > 0 || cs.chars.count > 0 {
        parts.append(cs)
      }
    }
  }

  public mutating func startAlternative() {
    currentAlternative = GlobMatcherAlternativePart()
  }

  public mutating func addAlternativeName(bytes: [UInt8]) {
    currentAlternative!.addBytes(bytes)
  }

  public mutating func saveAlternative() {
    if currentAlternative!.bytes.count > 0 {
      parts.append(currentAlternative!)
    }
  }

  public func assembleMatcher() -> ByteMatcher {
    var m = ByteMatcher()
    var lastType: GlobMatcherType?
    for part in parts {
      switch part.type {
        case .Name:
          let namePart = part as! GlobMatcherNamePart
          let bytes = ignoreCase ? Ascii.toLowerCase(namePart.bytes) :
              namePart.bytes
          if lastType == .Any {
            m.eatUntilIncludingBytes(bytes)
          } else {
            m.eatBytes(bytes)
          }
        case .Any: () // Ignore.
        case .One:
          m.next()
        case .Set: ()
          var setPart = part as! GlobMatcherSetPart
          setPart.ignoreCase = ignoreCase
          let table = setPart.makeComparisonTable()
          if setPart.isNegated {
            m.eatOneNotFromTable(table)
          } else {
            m.eatBytesFromTable(table)
          }
        case .Alternative:
          let altPart = part as! GlobMatcherAlternativePart
          let bytes = ignoreCase ? Ascii.toLowerCase(altPart.bytes) :
              altPart.bytes
          if lastType == .Any {
            m.eatUntilIncludingBytesFromList(bytes)
          } else {
            m.eatBytesFromList(bytes)
          }
      }
      lastType = part.type
    }
    if lastType == .Any {
      m.skipToEnd()
    }
    return m
  }

  public static func parse(string: String) throws -> GlobMatcher {
    let tokens = try GlobLexer(bytes: string.bytes).parseAllGlobTokens()
    let len = tokens.count
    var m = GlobMatcher()
    if len > 0 {
      if tokens[len - 1].globType == .Text {
        throw GlobMatcherError.Parse
      }
      var i = 0
      while i < len {
        let token = tokens[i]
        switch token.globType {
          case .Name:
            m.addName(token.collect())
          case .SymAsterisk:
            m.addAny()
          case .SymQuestionMark:
            m.addOne()
          case .SymOBSet:
            m.startSet()
            i += 1
            SET: while i < len {
              let t = tokens[i]
              switch t.globType {
                case .SetChar:
                  m.addSetChar(t.bytes[t.startIndex])
                case .SetRange:
                  m.addSetRange(t.bytes[t.startIndex],
                      c2: t.bytes[t.startIndex + 2])
                case .SymCBSet:
                  break SET
                default:
                  throw GlobMatcherError.Parse
              }
              i += 1
            }
            m.saveSet()
          case .SymOBOptionalName:
            if i + 1 < len && tokens[i + 1].globType == .SymCBOptionalName {
              i += 1
              continue
            }
            m.startAlternative()
            i += 1
            while i < len {
              let t = tokens[i]
              if t.globType == .OptionalName {
                m.addAlternativeName(t.collect())
                i += 1
                if i < len {
                  let gt = tokens[i].globType
                  if gt == .SymCBOptionalName {
                    break
                  } else if gt == .SymComma {
                    i += 1
                    continue
                  }
                }
                throw GlobMatcherError.Parse
              } else {
                throw GlobMatcherError.Parse
              }
            }
            m.saveAlternative()
          default:
            GlobMatcherError.Unreachable
        }
        i += 1
      }
    }
    return m
  }

}


public enum GlobMatcherError: ErrorType {
  case Parse
  case Unreachable
}
