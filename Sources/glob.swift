

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


enum GlobTokenType: TokenType {
  case Text
  case Name
  case SymAsterisk           // *
  case SymQuestionMark       // ?
  case SymExclamation        // ! for negation of a set.
  case SetChar               // Non-range elements of a set.
  case SetLowerCaseRange     // a-b
  case SetUpperCaseRange     // A-Z
  case SetDigitRange         // 0-9
  case SymOBSet              // [
  case SymCBSet              // ]
  case OptionalName
  case SymOBOptionalName     // {
  case SymCommaOptionalName  // ,
  case SymCBOptionalName     // }
}


class GlobLexer: CommonLexer {

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
      return .SymCommaOptionalName
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
          return .SetLowerCaseRange
        }
        stream.currentIndex -= 1
      }
      return .SetChar
    } else if stream.eatUpperCase() {
      if stream.eatMinus() {
        if stream.eatUpperCase() {
          return .SetUpperCaseRange
        }
        stream.currentIndex -= 1
      }
      return .SetChar
    } else if stream.eatDigit() {
      if stream.eatMinus() {
        if stream.eatDigit() {
          return .SetDigitRange
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

}


public class Ascii {

  public static func toLowerCase(c: UInt8) -> UInt8 {
    if c >= 97 && c <= 122 {
      return c - 32
    }
    return c
  }

  public static func toLowerCase(bytes: [UInt8]) -> [UInt8] {
    var a = bytes
    let len = a.count
    for i in 0..<len {
      let c = a[i]
      if c >= 97 && c <= 122 {
        a[i] = c - 32
      }
    }
    return a
  }

}


enum GlobMatcherType {
  case Name
  case Any
  case One
  case Set
  case Alternative
}


protocol GlobMatcherPart {
  var type: GlobMatcherType { get }
}


struct GlobMatcherNamePart: GlobMatcherPart {

  var type: GlobMatcherType
  var bytes: [UInt8]

  init(bytes: [UInt8]) {
    type = .Name
    self.bytes = bytes
  }

}


struct GlobMatcherAnyPart: GlobMatcherPart {

  var type = GlobMatcherType.Any

}


struct GlobMatcherOnePart: GlobMatcherPart {

  var type = GlobMatcherType.One

}


struct GlobMatcherSetPart: GlobMatcherPart {

  var type: GlobMatcherType
  var chars: [UInt8]
  var ranges: [UInt8]
  var negated: Bool

  init() {
    type = .Set
    chars = []
    ranges = []
    negated = false
  }

  mutating func addChar(c: UInt8) {
    chars.append(c)
  }

  mutating func addRange(c1: UInt8, c2: UInt8) {
    if c1 < c2 {
      ranges.append(c1)
      ranges.append(c2)
    } else {
      ranges.append(c2)
      ranges.append(c1)
    }
  }

  mutating func negate() {
    negated = true
  }

  func makeComparisonTable() -> FirstCharTable {
    var table = FirstCharTable(count: 256, repeatedValue: nil)
    for c in chars {
      table[Int(c)] = FirstCharTableValue
    }
    var i = 0
    let len = ranges.count
    while i < len {
      var n = ranges[i]
      let n2 = ranges[i + 1]
      while n <= n2 {
        table[Int(n)] = FirstCharTableValue
        n += 1
      }
      i += 2
    }
    return table
  }

  var isNegated: Bool {
    return negated
  }

}


struct GlobMatcherAlternativePart: GlobMatcherPart {

  var type: GlobMatcherType
  var bytes: [[UInt8]]

  init() {
    type = .Alternative
    bytes = []
  }

  mutating func addBytes(bytes: [UInt8]) {
    self.bytes.append(bytes)
  }

}


struct GlobMatcher {

  var parts = [GlobMatcherPart]()
  var currentSet: GlobMatcherSetPart?
  var currentAlternative: GlobMatcherAlternativePart?

  mutating func addName(bytes: [UInt8]) {
    parts.append(GlobMatcherNamePart(bytes: bytes))
  }

  mutating func addAny() {
    parts.append(GlobMatcherAnyPart())
  }

  mutating func addOne() {
    parts.append(GlobMatcherOnePart())
  }

  mutating func startSet() {
    currentSet = GlobMatcherSetPart()
  }

  mutating func addSetChar(c: UInt8) {
    currentSet!.addChar(c)
  }

  mutating func addSetRange(c1: UInt8, c2: UInt8) {
    currentSet!.addRange(c1, c2: c2)
  }

  mutating func negateSet() {
    currentSet!.negate()
  }

  mutating func saveSet() {
    parts.append(currentSet!)
  }

  mutating func startAlternative() {
    currentAlternative = GlobMatcherAlternativePart()
  }

  mutating func addAlternativeName(bytes: [UInt8]) {
    currentAlternative!.addBytes(bytes)
  }

  mutating func saveAlternative() {
    parts.append(currentAlternative!)
  }

  func assembleMatcher() -> ByteMatcher {
    var m = ByteMatcher()
    var lastType: GlobMatcherType?
    for part in parts {
      switch part.type {
        case .Name:
          let namePart = part as! GlobMatcherNamePart
          if lastType == .Any {
            m.eatUntilIncludingBytes(namePart.bytes)
          } else {
            m.eatBytes(namePart.bytes)
          }
        case .Any: () // Ignore.
        case .One:
          m.next()
        case .Set: ()
          let setPart = part as! GlobMatcherSetPart
          let table = setPart.makeComparisonTable()
          if setPart.isNegated {
            m.eatOneNotFromTable(table)
          } else {
            m.eatBytesFromTable(table)
          }
        case .Alternative:
          let altPart = part as! GlobMatcherAlternativePart
          if lastType == .Any {
            m.eatUntilIncludingBytesFromList(altPart.bytes)
          } else {
            m.eatBytesFromList(altPart.bytes)
          }
      }
      lastType = part.type
    }
    if lastType == .Any {
      m.skipToEnd()
    }
    return m
  }

}
