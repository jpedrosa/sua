

public enum GlobLexerTokenizer: LexerTokenizer {
  case OptionalNameComma
  case OptionalName
  case OptionalNameMaybeEmpty
  case SetMinusChar
  case SetLowerCaseMinus
  case SetUpperCaseMinus
  case SetDigitMinus
  case Set
  case SetCharMaybeEmpty
  case SetNegation
  case SetMaybeEmpty
  case Body
  case Root
  case Text
}


enum GlobTokenType: String, TokenType {
  case Text = "text"
  case Separator = "separator"
  case Name = "name"
  case Symbol = "symbol"
}


class GlobLexer: CommonLexer {

  typealias T = GlobLexerTokenizer

  override init(stream: ByteStream) {
    let st = CommonLexerStatus(tokenizer: T.Root, spaceTokenizer: nil)
    super.init(stream: stream, status: st)
    defaultTokenizer = T.Text
  }

  override func next(tokenizer: LexerTokenizer) -> TokenType {
    switch(tokenizer as! GlobLexerTokenizer) {
      case .OptionalNameComma:
        return inOptionalNameComma()
      case .OptionalName:
        return inOptionalName()
      case .OptionalNameMaybeEmpty:
        return inOptionalNameMaybeEmpty()
      case .SetMinusChar:
        return inSetMinusChar()
      case .SetLowerCaseMinus:
        return inSetLowerCaseMinus()
      case .SetUpperCaseMinus:
        return inSetUpperCaseMinus()
      case .SetDigitMinus:
        return inSetDigitMinus()
      case .Set:
        return inSet()
      case .SetCharMaybeEmpty:
        return inSetCharMaybeEmpty()
      case .SetNegation:
        return inSetNegation()
      case .SetMaybeEmpty:
        return inSetMaybeEmpty()
      case .Body:
        return inBody()
      case .Root:
        return inRoot()
      case .Text:
        return inText()
    }
  }

  func isContextChar(c: UInt8) -> Bool {
    return c == 47 || c == 42 || c == 63 || c == 123 || c == 91 // / * ? { [
  }

  func inOptionalNameComma() -> GlobTokenType {
    if stream.eatComma() {
      status.tokenizer = T.OptionalName
      return .Symbol
    } else if stream.eatCloseBrace() {
      status.tokenizer = T.Body
      return .Symbol
    }
    return inText()
  }

  func inOptionalName() -> GlobTokenType {
    if stream.eatWhileNeitherTwo(125, c2: 44) { // } ,
      status.tokenizer = T.OptionalNameComma
      return .Name
    }
    return inText()
  }

  func inOptionalNameMaybeEmpty() -> GlobTokenType {
    if stream.eatCloseBrace() {
      status.tokenizer = T.Body
      return .Symbol
    }
    return inOptionalName()
  }

  func inSetMinusChar() -> GlobTokenType {
    stream.next()
    status.tokenizer = T.Set
    return .Name
  }

  func inSetLowerCaseMinus() -> GlobTokenType {
    stream.eatMinus()
    if stream.matchLowerCase() >= 0 {
      status.tokenizer = T.SetMinusChar
      return .Symbol
    }
    status.tokenizer = T.Set
    return .Name
  }

  func inSetUpperCaseMinus() -> GlobTokenType {
    stream.eatMinus()
    if stream.matchUpperCase() >= 0 {
      status.tokenizer = T.SetMinusChar
      return .Symbol
    }
    status.tokenizer = T.Set
    return .Name
  }

  func inSetDigitMinus() -> GlobTokenType {
    stream.eatMinus()
    if stream.matchDigit() >= 0 {
      status.tokenizer = T.SetMinusChar
      return .Symbol
    }
    status.tokenizer = T.Set
    return .Name
  }

  func inSet() -> GlobTokenType {
    status.tokenizer = T.Set
    if stream.eatCloseBracket() {
      status.tokenizer = T.Body
      return .Symbol
    } else if stream.eatLowerCase() {
      if stream.matchMinus() {
        status.tokenizer = T.SetLowerCaseMinus
      }
      return .Name
    } else if stream.eatUpperCase() {
      if stream.matchMinus() {
        status.tokenizer = T.SetUpperCaseMinus
      }
      return .Name
    } else if stream.eatDigit() {
      if stream.matchMinus() {
        status.tokenizer = T.SetDigitMinus
      }
      return .Name
    } else if stream.next() != nil {
      return .Name
    }
    return inText()
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
      return .Symbol
    }
    return inSetCharMaybeEmpty()
  }

  func inSetMaybeEmpty() -> GlobTokenType {
    if stream.eatCloseBracket() {
      return inText()
    }
    return inSetNegation()
  }

  func inBody() -> GlobTokenType {
    if stream.eatSlash() {
      return .Separator
    } else if stream.eatAsterisk() {
      stream.eatAsterisk()
      return .Symbol
    } else if stream.eatQuestionMark() {
      return .Symbol
    } else if stream.eatOpenBrace() {
      status.tokenizer = T.OptionalNameMaybeEmpty
      return .Symbol
    } else if stream.eatOpenBracket() {
      status.tokenizer = T.SetMaybeEmpty
      return .Symbol
    }
    stream.eatUntil(isContextChar)
    return .Name
  }

  func inRoot() -> GlobTokenType {
    status.tokenizer = T.Body
    if stream.eatSlash() {
      return .Separator
    }
    return inBody()
  }

  func inText() -> GlobTokenType {
    stream.skipToEnd()
    status.tokenizer = T.Text
    return .Text
  }

}
