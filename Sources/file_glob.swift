

public enum FileGlobTokenizer: Tokenizer {
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


enum FileGlobTokenType: TokenType {
  case Text
  case Separator
  case Name
  case Symbol
  case SymAsterisk           // *
  case SymQuestionMark       // ?
  case SymCircumflex         // ^
  case SetName               // Second part of [a-b] It's "b".
  case SetLowerName
  case SetUpperName
  case SetDigitName
  case SymOBSet              // [
  case SymMinusSet           // -
  case SymCBSet              // ]
  case OptionalName
  case SymOBOptionalName     // {
  case SymCommaOptionalName  // ,
  case SymCBOptionalName     // }
}


class FileGlobLexer: CommonLexer {

  typealias T = FileGlobTokenizer

  init(bytes: [UInt8]) {
    var st = CommonLexerStatus(tokenizer: T.Root)
    st.defaultTokenizer = T.Text
    super.init(bytes: bytes, status: st)
  }

  override func next(tokenizer: Tokenizer) -> TokenType {
    switch(tokenizer as! FileGlobTokenizer) {
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

  func inOptionalNameComma() -> FileGlobTokenType {
    if stream.eatComma() {
      status.tokenizer = T.OptionalName
      return .SymCommaOptionalName
    } else if stream.eatCloseBrace() {
      status.tokenizer = T.Body
      return .SymCBOptionalName
    }
    return inText()
  }

  func inOptionalName() -> FileGlobTokenType {
    if stream.eatWhileNeitherTwo(125, c2: 44) { // } ,
      status.tokenizer = T.OptionalNameComma
      return .OptionalName
    }
    return inText()
  }

  func inOptionalNameMaybeEmpty() -> FileGlobTokenType {
    if stream.eatCloseBrace() {
      status.tokenizer = T.Body
      return .SymCBOptionalName
    }
    return inOptionalName()
  }

  func inSetMinusChar() -> FileGlobTokenType {
    stream.next()
    status.tokenizer = T.Set
    return .SetName
  }

  func inSetLowerCaseMinus() -> FileGlobTokenType {
    if stream.eatMinus() && stream.matchLowerCase() >= 0 {
      status.tokenizer = T.SetMinusChar
      return .SymMinusSet
    }
    return inText()
  }

  func inSetUpperCaseMinus() -> FileGlobTokenType {
    if stream.eatMinus() && stream.matchUpperCase() >= 0 {
      status.tokenizer = T.SetMinusChar
      return .SymMinusSet
    }
    return inText()
  }

  func inSetDigitMinus() -> FileGlobTokenType {
    if stream.eatMinus() && stream.matchDigit() >= 0 {
      status.tokenizer = T.SetMinusChar
      return .SymMinusSet
    }
    return inText()
  }

  func inSet() -> FileGlobTokenType {
    status.tokenizer = T.Set
    if stream.eatCloseBracket() {
      status.tokenizer = T.Body
      return .SymCBSet
    } else if stream.eatLowerCase() {
      if stream.matchMinus() {
        status.tokenizer = T.SetLowerCaseMinus
        return .SetLowerName
      }
      return inText()
    } else if stream.eatUpperCase() {
      if stream.matchMinus() {
        status.tokenizer = T.SetUpperCaseMinus
        return .SetUpperName
      }
      return inText()
    } else if stream.eatDigit() {
      if stream.matchMinus() {
        status.tokenizer = T.SetDigitMinus
        return .SetDigitName
      }
      return inText()
    } else if stream.next() != nil {
      return .Name
    }
    return inText()
  }

  func inSetCharMaybeEmpty() -> FileGlobTokenType {
    if stream.eatCloseBracket() {
      return inText()
    }
    return inSet()
  }

  func inSetNegation() -> FileGlobTokenType {
    if stream.eatCircumflex() {
      status.tokenizer = T.Set
      return .SymCircumflex
    }
    return inSetCharMaybeEmpty()
  }

  func inSetMaybeEmpty() -> FileGlobTokenType {
    if stream.eatCloseBracket() {
      return inText()
    }
    return inSetNegation()
  }

  func inBody() -> FileGlobTokenType {
    if stream.eatSlash() {
      return .Separator
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

  func inRoot() -> FileGlobTokenType {
    status.tokenizer = T.Body
    if stream.eatSlash() {
      return .Separator
    }
    return inBody()
  }

  func inText() -> FileGlobTokenType {
    stream.skipToEnd()
    status.tokenizer = T.Text
    return .Text
  }

}
