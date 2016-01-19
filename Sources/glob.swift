

public enum GlobTokenizer: Tokenizer {
  case OptionalNameComma
  case OptionalName
  case OptionalNameMaybeEmpty
  case Set
  case SetCharMaybeEmpty
  case SetNegation
  case SetMaybeEmpty
  case Body
  case Text
  case EscapeCharacter
}


enum GlobTokenType: TokenType {
  case Text
  case Name
  case Symbol
  case SymAsterisk           // *
  case SymQuestionMark       // ?
  case SymCircumflex         // ^ for negation of a set.
  case SetChar               // Non-range elements of a set.
  case SetLowerCaseRange     // a-b
  case SetUpperCaseRange     // A-Z
  case SetDigitRange         // 0-9
  case SetLowerChar
  case SetUpperChar
  case SetDigitChar
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
    var st = CommonLexerStatus(tokenizer: T.Body)
    st.defaultTokenizer = T.Text
    super.init(bytes: bytes, status: st)
  }

  override func next(tokenizer: Tokenizer) -> TokenType {
    switch(tokenizer as! GlobTokenizer) {
      case .OptionalNameComma:
        return inOptionalNameComma()
      case .OptionalName:
        return inOptionalName()
      case .OptionalNameMaybeEmpty:
        return inOptionalNameMaybeEmpty()
      case .Set:
        return inSet()
      case .SetCharMaybeEmpty:
        return inSetCharMaybeEmpty()
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

  func inOptionalNameMaybeEmpty() -> GlobTokenType {
    if stream.eatCloseBrace() {
      status.tokenizer = T.Body
      return .SymCBOptionalName
    }
    return inOptionalName()
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

  func inSetCharMaybeEmpty() -> GlobTokenType {
    if stream.eatCloseBracket() {
      return inText()
    }
    return inSet()
  }

  func inSetNegation() -> GlobTokenType {
    if stream.eatCircumflex() {
      status.tokenizer = T.Set
      return .SymCircumflex
    }
    return inSetCharMaybeEmpty()
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
      status.tokenizer = T.OptionalNameMaybeEmpty
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
